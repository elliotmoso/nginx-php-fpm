#!/bin/bash

# Disable Strict Host checking
mkdir -p -m 0700 /root/.ssh
echo -e "Host *\n\tStrictHostKeyChecking no\n" >> /root/.ssh/config

# Tweak nginx to match the workers to cpu's
procs=$(cat /proc/cpuinfo |grep processor | wc -l)
sed -i -e "s/worker_processes 5/worker_processes $procs/" /etc/nginx/nginx.conf

# Configure How may PHP-FPM Children
PHP_CHILDREN=${PHP_CHILDREN:-false}
if [ "$PHP_CHILDREN" != "false" ]; then
    sed -i "s/^pm.max_children = .*/pm.max_children = \"${PHP_CHILDREN}\"/" /etc/php5/fpm/pool.d/www.conf
fi

# Configure NewRelic if need.

NEWRELIC_LICENSE=${NEWRELIC_LICENSE:-false}
if [ "$NEWRELIC_LICENSE" != "false" ]; then
    sed -i "s/^;newrelic.enabled = .*/newrelic_enabled = true/" /etc/php5/fpm/conf.d/20-newrelic.ini
    sed -i "s/^newrelic.license = .*/newrelic.license = \"${NEWRELIC_LICENSE}\"/" /etc/php5/fpm/conf.d/20-newrelic.ini
    sed -i "s/^;newrelic.error_collector.enabled = .*/newrelic.error_collector.enabled = true/" /etc/php5/fpm/conf.d/20-newrelic.ini
    sed -i "s/^;newrelic.transaction_tracer.enabled = .*/newrelic.transaction_tracer.enabled = true/" /etc/php5/fpm/conf.d/20-newrelic.ini
    sed -i "s/^;newrelic.transaction_tracer.threshold = .*/newrelic.transaction_tracer.threshold = \"apdex_f\"/" /etc/php5/fpm/conf.d/20-newrelic.ini
    sed -i "s/^;newrelic.transaction_events.enabled = .*/newrelic.transaction_events.enabled = true/" /etc/php5/fpm/conf.d/20-newrelic.ini
fi

NEWRELIC_APP=${NEWRELIC_APP:-false}
if [ "$NEWRELIC_APP" != "false" ]; then
    sed -i "s/^newrelic.appname = .*/newrelic.appname = \"${NEWRELIC_APP}\"/" /etc/php5/fpm/conf.d/20-newrelic.ini
fi

# Start supervisord and services
/usr/bin/supervisord -n -c /etc/supervisord.conf
