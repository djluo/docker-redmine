#!/usr/bin/env puma
directory       '/redmine/'
environment     'production'
pidfile         '/tmp/puma.pid'
state_path      '/tmp/puma.state'
#bind            'tcp://0.0.0.0:9292'
bind            'unix:///redmine/logs/puma.sock?umask=0111'
#workers         2
daemonize       false
stdout_redirect '/redmine/logs/stdout.log', '/redmine/logs/stderr.log', true
preload_app!
