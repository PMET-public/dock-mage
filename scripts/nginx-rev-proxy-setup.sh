#!/usr/bin/env bash

# stop on errors
set -e
# turn on debugging
set -x

docker_host_ip=$(docker run --rm --privileged --pid=host debian:stable-slim nsenter -t 1 -m -u -n -i sh -c "ip route|awk '/default/{print \$3}'")

mkdir /tmp/conf.d || :

for network in $(docker network ls | grep default | grep bridge | awk '{print $2}'); do

  varnish_port=$(docker ps -a --filter "network=${network}" --filter "label=com.docker.compose.service=varnish" --format "{{.Ports}}" | sed 's/.*://;s/-.*//')
  magento_hostname=$(docker ps -a --filter "network=${network}" --filter "label=com.docker.compose.service=app" --format "{{.Names}}")

  if [ ! -z "${varnish_port}" -a ! -z "${magento_hostname}" ];then

  echo "Writing nginx conf file for ${magento_hostname}"
  cat << EOF > /tmp/conf.d/host-$magento_hostname.conf
    server {
      listen 443 ssl http2;
      server_name  $magento_hostname;
      ssl_certificate /etc/letsencrypt/live/$magento_hostname/fullchain.pem;
      ssl_certificate_key /etc/letsencrypt/live/$magento_hostname/privkey.pem;
      location / {
        proxy_pass http://$docker_host_ip:$varnish_port;
        proxy_set_header Host \$host;
        proxy_set_header X-Forwarded-Proto \$scheme;
      }
    }
EOF

else

  echo "Either varnish or app service not found on network ${network}. Skipping ..."

fi

done


# if running nginx proxy does not exist, create it, copy over conf, and start it
if [ -z $(docker ps -qa --filter 'name=^/nginx-rev-proxy$') ]; then
  docker create --name nginx-rev-proxy --hostname nginx-rev-proxy  -v /etc/letsencrypt:/etc/letsencrypt -p 443:443 pmetpublic/nginx
  docker cp /tmp/conf.d nginx-rev-proxy:/etc/nginx/
  docker start nginx-rev-proxy
else
  # else remove old, copy new, and reload config
  docker exec nginx-rev-proxy rm /etc/nginx/conf.d/host-*.conf || :
  docker cp /tmp/conf.d nginx-rev-proxy:/etc/nginx/
  docker exec nginx-rev-proxy nginx -s reload
fi
