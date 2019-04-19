#!/usr/bin/env bash

# stop on errors
set -e

# show debug info if debug is set
if [[ ! -z "${debug}" ]]; then
  set -x
fi

SCRIPTS_DIR=$( cd $(dirname $0) ; pwd -P )

full_path=$(cd "${SCRIPTS_DIR}"/../../../.. && pwd -P)
dir_name=$(basename "${full_path}")
if [[ 
  "${COMPOSE_PROJECT_NAME}" != "${dir_name}" ||
  "${COMPOSE_FILE}" != "${full_path}/vendor/magentoese/dock-mage/docker-compose.yml" ||
  "${COMPOSE_PROJECT_NAME}" != "${mhost}" 
]]; then
  echo -e "Before continuing, please run:\n\033[32mexport COMPOSE_PROJECT_NAME=\"${dir_name}\" COMPOSE_FILE=\"${full_path}/vendor/magentoese/dock-mage/docker-compose.yml\" mhost=\"${dir_name}\"\033[0m"
  exit
fi
exit
if ! ( pip3 freeze | grep -q PyYAML) ; then
  echo "Please ensure you have python3, pip3, and PyYAML before continuing ..." && exit 1
fi


# if a value is echoed, it's for use in the calling env
# if a value is exported, it's to be used in the docker-compose.yml

interpolate_ini() {
  perl -pe 's/\s*#.*//;s/^\s*$//;s/\${([^:]*):-([^}]*)}/exists $ENV{$1} && $ENV{$1} ne "" ? $ENV{$1} : $2/e' $@
}

if [ ! -f "${SCRIPTS_DIR}"/../env/private.ini ]; then 
  cp "${SCRIPTS_DIR}"/../env/private.ini.template "${SCRIPTS_DIR}"/../env/private.ini
fi

for ini in "${SCRIPTS_DIR}"/../env/*.ini; do
  # output vars so they can exported in calling shell
  interpolate_ini $ini
  # export same vars in this process so they can be used in remaining var declarations
  export $(interpolate_ini $ini)
done



# write config files with exported env vars if defined
perl -pe 's/\${([^}]*)}/exists $ENV{$1} ? $ENV{$1} : ""/ge' "${SCRIPTS_DIR}"/../etc/blackfire/agent.template > "${SCRIPTS_DIR}"/../etc/blackfire/agent
perl -pe 's/\${([^}]*)}/exists $ENV{$1} ? $ENV{$1} : ""/ge' "${SCRIPTS_DIR}"/../etc/php/blackfire.ini.template > "${SCRIPTS_DIR}"/../etc/php/blackfire.ini
perl -pe 's/\${([^}]*)}/exists $ENV{$1} ? $ENV{$1} : ""/ge' "${SCRIPTS_DIR}"/../etc/php/xdebug.ini.template > "${SCRIPTS_DIR}"/../etc/php/xdebug.ini

echo MAGENTO_CLOUD_TREE_ID=$(cd "${SCRIPTS_DIR}/../../../.."; git rev-parse HEAD)
echo MAGENTO_CLOUD_BRANCH=$(cd "${SCRIPTS_DIR}/../../../.."; git rev-parse --abbrev-ref HEAD)

echo MAGENTO_CLOUD_RELATIONSHIPS=$(cat "${SCRIPTS_DIR}"/../env/MAGENTO_CLOUD_RELATIONSHIPS.yaml |
  python3 -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' |
  base64)

echo MAGENTO_CLOUD_VARIABLES=$(cat "${SCRIPTS_DIR}"/../env/MAGENTO_CLOUD_VARIABLES.yaml |
  python3 -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' |
  base64)

# need to append original url b/c deploy scripts expecting this value in MAGENTO_CLOUD_ROUTES but it's not a recognized key in .magento/routes.yaml
tmp_yaml=$(cat "${SCRIPTS_DIR}"/../../../../.magento/routes.yaml <(echo '    original_url: "https://{default}/"'))
echo MAGENTO_CLOUD_ROUTES=$(echo "${tmp_yaml}" |
  perl -pe 's/{default}\/":/exists $ENV{"mhost"} ? $ENV{"mhost"}."\/\":" : die "HOSTNAME undefined"/ge' |
  python3 -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' |
  base64)

if [ ! -z "$(docker ps -qa --filter "name=^/${mhost}\$")" ]; then
  >&2 echo -e "\nContainer with name ${mhost} already exists. If you want to create a new container, use:\n\n\033[33mexport mhost=www.sample.com\033[0m"
fi

if [ ! -z "$(docker-compose ps -q 2>/dev/null)" ]; then
  >&2 echo -e "\nProject with name ${COMPOSE_PROJECT_NAME} already exists. If you want to create a new project, use:\n\n\033[33mexport COMPOSE_PROJECT_NAME=myprefix\033[0m"
fi
