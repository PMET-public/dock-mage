#!/usr/bin/env bash

SCRIPTS_DIR=$( cd $(dirname $0) ; pwd -P )


# if a value is echoed, it's for use in the calling env
# if a value is exported, it's to be used in the docker-compose.yml

for ini in "${SCRIPTS_DIR}"/../env/*.ini; do
  # output vars so they can exported in calling shell
  perl -pe 's/\s*#.*//;s/^\s*$//;s/\${([^:]*):-([^}]*)}/exists $ENV{$1} ? $ENV{$1} : $2/e' $ini
  # export same vars in this process so they can be used in remaining var declarations
  export $(perl -pe 's/\s*#.*//;s/^\s*$//;s/\${([^:]*):-([^}]*)}/exists $ENV{$1} ? $ENV{$1} : $2/e' $ini)
done

export XDEBUG_REMOTE_HOST=$(docker run --rm --privileged --pid=host debian:stable-slim nsenter -t 1 -m -u -n -i sh -c "ip route|awk '/default/{print \$3}'")
echo COMPOSE_PROJECT_NAME=$( [[ -n "${COMPOSE_PROJECT_NAME}" ]] && echo "${COMPOSE_PROJECT_NAME}" || basename $(cd "${SCRIPTS_DIR}"/../../../.. && pwd) )
export MAGENTO_HOSTNAME=$( [[ -n "${COMPOSE_PROJECT_NAME}" ]] && echo "${COMPOSE_PROJECT_NAME}" || basename $(cd "${SCRIPTS_DIR}"/../../../.. && pwd) )
echo "MAGENTO_HOSTNAME=${MAGENTO_HOSTNAME}"


# write config files with exported env vars if defined
perl -pe 's/\${([^}]*)}/exists $ENV{$1} ? $ENV{$1} : ""/ge' "${SCRIPTS_DIR}"/../etc/blackfire/agent.template > "${SCRIPTS_DIR}"/../etc/blackfire/agent
perl -pe 's/\${([^}]*)}/exists $ENV{$1} ? $ENV{$1} : ""/ge' "${SCRIPTS_DIR}"/../etc/php/blackfire.ini.template > "${SCRIPTS_DIR}"/../etc/php/blackfire.ini
perl -pe 's/\${([^}]*)}/exists $ENV{$1} ? $ENV{$1} : ""/ge' "${SCRIPTS_DIR}"/../etc/php/xdebug.ini.template > "${SCRIPTS_DIR}"/../etc/php/xdebug.ini

echo MAGENTO_CLOUD_TREE_ID=$(cd "${SCRIPTS_DIR}/../../../.."; git rev-parse HEAD)
echo MAGENTO_CLOUD_BRANCH=$(cd "${SCRIPTS_DIR}/../../../.."; git rev-parse --abbrev-ref HEAD)

echo MAGENTO_CLOUD_RELATIONSHIPS=$(cat "${SCRIPTS_DIR}"/../env/MAGENTO_CLOUD_RELATIONSHIPS.yaml |
  python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' |
  base64)

echo MAGENTO_CLOUD_VARIABLES=$(cat "${SCRIPTS_DIR}"/../env/MAGENTO_CLOUD_VARIABLES.yaml |
  python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' |
  base64)

# need to append original url b/c deploy scripts expecting this value in MAGENTO_CLOUD_ROUTES but it's not a recognized key in .magento/routes.yaml
tmp_yaml=$(cat "${SCRIPTS_DIR}"/../../../../.magento/routes.yaml <(echo '    original_url: "https://{default}/"'))
echo MAGENTO_CLOUD_ROUTES=$(echo "${tmp_yaml}" |
  perl -pe 's/{default}\/":/exists $ENV{"MAGENTO_HOSTNAME"} ? $ENV{"MAGENTO_HOSTNAME"}."\/\":" : die "HOSTNAME undefined"/ge' |
  python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' |
  base64)

if [ ! -z "$(docker ps -qa --filter "name=^/${MAGENTO_HOSTNAME}\$")" ]; then
  >&2 echo -e "\nContainer with name ${MAGENTO_HOSTNAME} already exists. If you want to create a new container, use:\n\n\e[33mexport MAGENTO_HOSTNAME=www.sample.com\e[0m"
fi

if [ ! -z "$(docker-compose ps -q 2>/dev/null)" ]; then
  >&2 echo -e "\nProject with name ${COMPOSE_PROJECT_NAME} already exists. If you want to create a new project, use:\n\n\e[33mexport COMPOSE_PROJECT_NAME=myprefix\e[0m"
fi
