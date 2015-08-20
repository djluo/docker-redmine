# vim:set et ts=2 sw=2 syntax=dockerfile:

FROM       docker.xlands-inc.com/baoyu/ruby-puma
MAINTAINER djluo <dj.luo@baoyugame.com>

ENV  VER 3.1.0
ADD  ./redmine-${VER}.tar.gz /

COPY ./conf/database.yml /redmine-${VER}/config/

RUN export http_proxy="http://172.17.42.1:8080/" \
    && export DEBIAN_FRONTEND=noninteractive     \
    && apt-get update \
    && build="$build make binutils cpp cpp-4.7 gcc"       \
    && build="$build gcc-4.7 libc-dev-bin libc6-dev"      \
    && build="$build libffi5 libgmp10 libgomp1 libitm1"   \
    && build="$build libyaml-0-2 linux-libc-dev manpages" \
    && build="$build manpages-dev ruby-dev ruby1.9.1-dev" \
    && build="$build libmysqlclient-dev patch zlib1g-dev" \
    && build="$build libmpc2 libmpfr4 libquadmath0 libruby1.9.1" \
    && apt-get install -y $build \
    && gem install bundler \
    && cd /redmine-${VER}  \
    && ln -sv /redmine-${VER} /redmine \
    && bundle config mirror.https://rubygems.org http://ruby.taobao.org \
    && bundle install --clean --without development test postgresql rmagick \
    && apt-get purge -y $build \
    && apt-get install -y ruby \
    && gem cleanup   \
    && apt-get clean \
    && unset http_proxy DEBIAN_FRONTEND \
    && rm -rf /root/.gem        \
    && rm -rf /usr/share/locale \
    && rm -rf /usr/share/man    \
    && rm -rf /usr/share/doc    \
    && rm -rf /usr/share/info   \
    && rm -rf /var/lib/gems/1.9.1/cache/* \
    && find /var/lib/apt -type f -exec rm -f {} \;

COPY ./entrypoint.pl     /entrypoint.pl
COPY ./init.sh           /redmine-${VER}/
COPY ./conf/puma.rb      /redmine-${VER}/config/
COPY ./conf/additional_environment.rb /redmine-${VER}/config/

WORKDIR    /redmine-${VER}/
ENTRYPOINT ["/entrypoint.pl"]
CMD        ["/usr/local/bin/puma", "-w", "2"]
