#!/bin/bash
exec 1>/redmine/logs/init.out
exec 2>/redmine/logs/init.err

current_dir=`dirname $0`
current_dir=`readlink -f $current_dir`
cd ${current_dir} && export current_dir

LOCK="$1"

RAILS_ENV="production"
REDMINE_LANG="zh"

rake db:migrate \
  && rake redmine:load_default_data \
  && mkdir -p tmp tmp/pdf public/plugin_assets \
  && chown -R docker.docker files logs tmp public/plugin_assets \
  && chmod 750 files logs tmp public/plugin_assets \
  && /bin/rm -rf /nginx/public/* \
  && /bin/cp -a  ./public/* /nginx/public/ \
  && touch "${LOCK}"
