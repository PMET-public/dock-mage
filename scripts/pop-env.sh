#!/usr/bin/env bash


SCRIPTS_DIR=$( cd $(dirname $0) ; pwd -P )


for ini in "${SCRIPTS_DIR}"/../env/*.ini; do
  # output vars so they can exported in calling shell
  perl -pe "s/\s*#.*//;s/^\s*$//" $ini
  # export same vars in this process so they can be used in remaining var declarations
  export $(perl -pe "s/\s*#.*//;s/^\s*$//" $ini)
done

echo MAGENTO_CLOUD_VARIABLES=$(cat "${SCRIPTS_DIR}"/../env/MAGENTO_CLOUD_VARIABLES.yaml |
  python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' |
  base64)


echo MAGENTO_CLOUD_ROUTES=$(cat "${SCRIPTS_DIR}"/../../../../.magento/routes.yaml |
  perl -pe 's/{default}/exists $ENV{"MAGENTO_HOSTNAME"} ? $ENV{"MAGENTO_HOSTNAME"} : die "HOSTNAME undefined"/ge' |
  python -c 'import sys, yaml, json; json.dump(yaml.load(sys.stdin), sys.stdout, indent=4)' |
  base64)

#for ini in "${SCRIPTS_DIR}"/../env/*.ini; do
#  perl -pe 's/{{([a-zA-Z_]+[a-zA-Z0-9_]*)}}/exists $ENV{$1} ? $ENV{$1} : die "{{$1}} undefined in $ARGV"/ge' "${ini}"
#done
