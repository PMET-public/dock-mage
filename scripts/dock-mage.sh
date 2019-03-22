#!/usr/bin/env bash

# stop on errors
set -e
# turn on debugging if debug is set
if [[ ! -z "${debug}" ]]; then
  set -x
fi

run_hook() {
  python -c "import re,yaml;print(re.sub('\n?#.*','',yaml.load(open('.magento.app.yaml'))['hooks']['$1']).strip())"
}

case $variable in
  configure)      
    commands
  ;;
  up)      
    commands
  ;;
  cloud-build)
    run_hook build
  ;; 
  cloud-deploy)
    run_hook deploy
  ;;
  cloud-post-deploy)
    run_hook post_deploy
  ;;
  cloud-all)
    run_hook build
    run_hook deploy
    run_hook post_deploy
  ;;
  *)
    echo "option n/a"
  ;;
esac