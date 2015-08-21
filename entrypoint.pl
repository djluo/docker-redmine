#!/usr/bin/perl
# vim:set et ts=2 sw=2:

# Author : djluo
# version: 2.0(20150107)
#
# 初衷: 每个容器用不同用户运行程序,已方便在宿主中直观的查看.
# 需求: 1. 动态添加用户,不能将添加用户的动作写死到images中.
#       2. 容器内尽量不留无用进程,保持进程树干净.
# 问题: 如用shell的su命令切换,会遗留一个su本身的进程.
# 最终: 使用perl脚本进行添加和切换操作. 从环境变量User_Id获取用户信息.

use strict;
#use English '-no_match_vars';

my $uid = 1000;
my $gid = 1000;

$uid = $gid = $ENV{'User_Id'} if $ENV{'User_Id'} =~ /\d+/;

unless (getpwuid("$uid")){
  system("/usr/sbin/useradd", "-U", "-u $uid", "-m", "docker");
}

# init
my $db_conf="/redmine/config/database.yml";
system("chmod","640", "$db_conf") if ( -f "$db_conf");
if ( -f $db_conf && (stat($db_conf))[4] != $uid ){
  system("chgrp", "docker", "$db_conf");
}

my $secrt="/redmine/config/initializers/secret_token.rb";
system("rake", "generate_secret_token") unless ( -f $secrt);

my $ver_lock = "/nginx/public/redmine-". $ENV{'VER'} .".lock";
system("/redmine/init.sh", "$ver_lock") unless (-f "$ver_lock");

my @dirs = ("logs", "files","tmp", "public/plugin_assets");
   @dirs = map { "/redmine/" . $_ } @dirs;
foreach my $dir (@dirs) {
  if ( -d $dir && (stat($dir))[4] != $uid ){
    system("chown docker.docker -R " . $dir);
  }
}
system("chown docker.docker /redmine/logs/production.log");

# 信号处理,无法自行回收
$SIG{TERM} = sub {
  system("pumactl","stop")
};

my $pid=fork();
if ($pid != 0) {
  system("rm", "-f", "/run/crond.pid") if ( -f "/run/crond.pid" );
  system("/usr/sbin/cron");

  if( $ENV{'RSYNC_PASSWORD'} ){
    my $ip=$ENV{'backup_ip'};
    my $dest=$ENV{'backup_dest'}."_".$ENV{'HOSTNAME'};
    my $port="2873";
    $port="$ENV{'RSYNC_PORT'}" if ( $ENV{'RSYNC_PORT'} );
    my $rsync_opts = "/usr/bin/rsync --del --port=$port -al --password-file=/rsync.pass";

    my $umask = umask;
    umask 0277;
    open (PW,'>', '/rsync.pass') or die "$!";
    print PW $ENV{'RSYNC_PASSWORD'};
    close(PW);
    umask $umask;

    my $min  = int(rand(60));
    my $hour = int(rand(5));

    open (CRON,"|/usr/bin/crontab") or die "crontab error?";
    print CRON ("$min $hour * * * ($rsync_opts /redmine/files/ docker@". $ip ."::backup/$dest/)\n");
    close(CRON);
  }
  waitpid($pid,0);
}else{
  $( = $) = $gid; die "switch gid error\n" if $gid != $( ;
  $< = $> = $uid; die "switch uid error\n" if $uid != $< ;
  $ENV{'HOME'} = "/home/docker";
  exec(@ARGV);
}
