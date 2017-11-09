#!/usr/bin/env bash

# stop on errors
# set -e
# turn on debugging
# set -x


IFS=$'\n'

# look for template files below cur dir
for tmpl_conf_path in $(find . -path "*/templates/*"); do

  tmpl_conf_filename=$(basename ${tmpl_conf_path})
  tmpl_conf_dir=$(dirname ${tmpl_conf_path})

  # replace {{ENV_VAR}} with value or complain if ENV_VAR does not exist
  # save to new file parent dir
  perl -pe 's/{{([a-zA-Z_]+[a-zA-Z0-9_]*)}}/exists $ENV{$1} ? $ENV{$1} : die "{{$1}} undefined in $ARGV"/ge' "${tmpl_conf_path}" \
    > "${tmpl_conf_dir}/../${tmpl_conf_filename}"

  # add generated file to .gitignore
  git_ignore=$(git rev-parse --show-toplevel)/.gitignore
  git_prefix=$(cd "${tmpl_conf_dir}/../" && git rev-parse --show-prefix)
  if ! grep -q "${git_prefix}${tmpl_conf_filename}" "${git_ignore}"; then
    echo "${git_prefix}${tmpl_conf_filename}" >> "${git_ignore}";
  fi

done

# execute cmd after --
while [[ $# -gt 0 ]]; do
  case "$1" in
    --)
    shift
    cmd="$@"
    break
    ;;
    *)
    echoerr "Unknown argument: $1"
    usage
    ;;
  esac
done


if [[ $cmd != "" ]]; then
  exec $cmd
fi
