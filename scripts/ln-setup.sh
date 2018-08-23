#!/usr/bin/env bash

# stop on errors
set -e

ETC_DIR=$( cd $(dirname $0)/.. ; pwd -P )

ln -sf ${ETC_DIR}/apache2/sites-enabled /etc/apache2/sites-enabled
# map php ini settings to cli and apache dirs
ln -sf ${ETC_DIR}/php/apache2.ini /etc/php/7.0/apache2/conf.d/apache2.ini
ln -sf ${ETC_DIR}/php/cli.ini /etc/php/7.0/cli/conf.d/cli.ini
ln -sf ${ETC_DIR}/php/opcache.ini /etc/php/7.0/cli/conf.d/opcache.ini
ln -sf ${ETC_DIR}/php/opcache.ini /etc/php/7.0/apache2/conf.d/opcache.ini
ln -sf ${ETC_DIR}/php/blackfire.ini /etc/php/7.0/apache2/conf.d/blackfire.ini
ln -sf ${ETC_DIR}/php/blackfire.ini /etc/php/7.0/cli/conf.d/blackfire.ini
ln -sf ${ETC_DIR}/php/xdebug.ini /etc/php/7.0/apache2/conf.d/xdebug.ini
ln -sf ${ETC_DIR}/php/xdebug.ini /etc/php/7.0/cli/conf.d/xdebug.ini
ln -sf ${ETC_DIR}/blackfire/agent /etc/blackfire/agent