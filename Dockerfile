# vim:set et ts=2 sw=2 syntax=dockerfile:

FROM       docker.xlands-inc.com/baoyu/ruby-puma
MAINTAINER djluo <dj.luo@baoyugame.com>

ENV VER 3.2.0
ENV URL http://www.redmine.org/releases/redmine-${VER}.tar.gz

COPY ./conf/database.yml /redmine-${VER}/config/

RUN export http_proxy="http://172.17.42.1:8080/" \
    && export DEBIAN_FRONTEND=noninteractive     \
    && apt-get update \
    && build="$build make binutils cpp"       \
    && build="$build gcc libc-dev-bin libc6-dev"      \
    && build="$build libgmp10 libgomp1 libitm1"   \
    && build="$build libyaml-0-2 linux-libc-dev manpages" \
    && build="$build manpages-dev ruby-dev" \
    && build="$build libmysqlclient-dev patch zlib1g-dev" \
    && build="$build libmpfr4 libquadmath0 libruby" \
    && apt-get install -y $build \
    && unset http_proxy    \
    && gem install bundler \
    && curl -sLo /redmine.tar.gz $URL \
    && tar xf /redmine.tar.gz \
    && cd /redmine-${VER}     \
    && ln -sv /redmine-${VER} /redmine \
    && echo 'gem "rbpdf-font", "1.19.0"' > Gemfile.local \
    && bundle config mirror.https://rubygems.org https://ruby.taobao.org \
    && bundle install --clean --without development test postgresql rmagick \
    && export http_proxy="http://172.17.42.1:8080/" \
    && apt-get purge -y $build \
    && apt-get install -y ruby git \
    && gem cleanup   \
    && apt-get clean \
    && unset http_proxy DEBIAN_FRONTEND \
    && rm -rf /root/.gem        \
    && rm -rf /usr/share/locale \
    && rm -rf /usr/share/man    \
    && rm -rf /usr/share/doc    \
    && rm -rf /usr/share/info   \
    && rm -rf /var/lib/gems/*/cache/* \
    && find /var/lib/apt -type f -exec rm -f {} \;

COPY ./entrypoint.pl     /entrypoint.pl
COPY ./init.sh           /redmine-${VER}/
COPY ./conf/puma.rb      /redmine-${VER}/config/
COPY ./conf/additional_environment.rb /redmine-${VER}/config/

WORKDIR    /redmine-${VER}/
ENTRYPOINT ["/entrypoint.pl"]
CMD        ["/usr/local/bin/puma", "-w", "2"]
