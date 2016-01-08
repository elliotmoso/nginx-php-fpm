#!/bin/bash

# Disable Strict Host checking for non interactive git clones

mkdir -p -m 0700 /root/.ssh
echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config

# Setup git variables
#if [ ! -z "$GIT_EMAIL" ]; then
# git config --global user.email "$GIT_EMAIL"
#fi
#if [ ! -z "$GIT_NAME" ]; then
# git config --global user.name "$GIT_NAME"
# git config --global push.default simple
#fi

# Pull down code form git for our site!
#if [ ! -z "$GIT_REPO" ]; then
#  rm /usr/share/nginx/html/*
#  if [ ! -z "$GIT_BRANCH" ]; then
#    git clone -b $GIT_BRANCH $GIT_REPO /usr/share/nginx/html/
#  else
#    git clone $GIT_REPO /usr/share/nginx/html/
#  fi
#  chown -Rf nginx.nginx /usr/share/nginx/*
#fi

# Tweak nginx to match the workers to cpu's

procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s/worker_processes 5/worker_processes $procs/" /etc/nginx/nginx.conf

# Very dirty hack to replace variables in code with ENVIRONMENT values
#if [[ "$TEMPLATE_NGINX_HTML" != "0" ]] ; then
#  for i in $(env)
#  do
#    variable=$(echo "$i" | cut -d'=' -f1)
#    value=$(echo "$i" | cut -d'=' -f2)
#    if [[ "$variable" != '%s' ]] ; then
#      replace='\$\$_'${variable}'_\$\$'
#      find /usr/share/nginx/html -type f -exec sed -i -e 's/'${replace}'/'${value}'/g' {} \;
#    fi
#  done
#fi

# Configure NewRelic if need.

NEWRELIC_LICENSE=${NEWRELIC_LICENSE:-false}
if [ "$NEWRELIC_LICENSE" != "false" ]; then
    sed -i "s/^;newrelic.enabled = .*/newrelic_enabled = true/" /etc/php5/fpm/conf.d/newrelic.ini
    sed -i "s/^newrelic.license = .*/newrelic.license = \"${NEWRELIC_LICENSE}\"/" /etc/php5/fpm/conf.d/newrelic.ini
    sed -i "s/^;newrelic.error_collector.enabled = .*/newrelic.error_collector.enabled = true/" /etc/php5/fpm/conf.d/newrelic.ini
    sed -i "s/^;newrelic.transaction_tracer.enabled = .*/newrelic.transaction_tracer.enabled = true/" /etc/php5/fpm/conf.d/newrelic.ini
    sed -i "s/^;newrelic.transaction_tracer.threshold = .*/newrelic.transaction_tracer.threshold = \"apdex_f\"/" /etc/php5/fpm/conf.d/newrelic.ini
    sed -i "s/^;newrelic.transaction_events.enabled = .*/newrelic.transaction_events.enabled = true/" /etc/php5/fpm/conf.d/newrelic.ini
fi

NEWRELIC_APP=${NEWRELIC_APP:-false}
if [ "$NEWRELIC_APP" != "false" ]; then
    sed -i "s/^newrelic.appname = .*/newrelic.appname = \"${NEWRELIC_APP}\"/" /etc/php5/fpm/conf.d/newrelic.ini
fi

# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisord.conf
