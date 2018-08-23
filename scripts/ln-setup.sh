#!/usr/bin/env bash

# stop on errors
set -e
# turn on debugging
set -x

ETC_DIR=$( cd $(dirname $0)/../etc ; pwd -P )

ln -sf ${ETC_DIR}/apache2/sites-enabled /etc/apache2/sites-enabled
# map php ini settings to cli and apache dirs
PHP_CONF_DIR=$(php -i | sed -n '/php.ini$/ s|.*\(/etc/php/7..\).*|\1|p')
ln -sf ${ETC_DIR}/php/apache2.ini ${PHP_CONF_DIR}/apache2/conf.d/apache2.ini
ln -sf ${ETC_DIR}/php/cli.ini ${PHP_CONF_DIR}/cli/conf.d/cli.ini
ln -sf ${ETC_DIR}/php/opcache.ini ${PHP_CONF_DIR}/cli/conf.d/opcache.ini
ln -sf ${ETC_DIR}/php/opcache.ini ${PHP_CONF_DIR}/apache2/conf.d/opcache.ini
ln -sf ${ETC_DIR}/php/blackfire.ini ${PHP_CONF_DIR}/apache2/conf.d/blackfire.ini
ln -sf ${ETC_DIR}/php/blackfire.ini ${PHP_CONF_DIR}/cli/conf.d/blackfire.ini
ln -sf ${ETC_DIR}/php/xdebug.ini ${PHP_CONF_DIR}/apache2/conf.d/xdebug.ini
ln -sf ${ETC_DIR}/php/xdebug.ini ${PHP_CONF_DIR}/cli/conf.d/xdebug.ini
ln -sf ${ETC_DIR}/blackfire/agent /etc/blackfire/agent