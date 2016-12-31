#!/usr/bin/env bash

set -o errexit
set -o pipefail
set -o nounset

VERSION=1.0.0
SCRIPT_NAME=$(basename "${0}");

##############################################################################o#
# Action Controllers
################################################################################
switchAction()
{
  local flag="${1:-0}"
  local ext=$(echo "$SCRIPT_NAME" | sed 's/^\([a-z]*\).*/\1/')
  local ini=$(php --ini | grep -i $ext | head -1)
  ini=$(echo "$ini" | sed 's/[^/]*\(\/.*\),/\1/')

  if [ ! -f "${ini}" ]; then
      echo "> ERROR: No $ext INI file found ..." 1>&2 && return 1
  fi

  if [ "$flag" -eq 0 ]; then
      sed -i'' -e 's/^\([a-z_]*extension\)/;\1/g' "${ini}" \
        && echo "> $ext DISABLED in ${ini}" \
        || { echo "> ERROR: failed to update ${ini} file ..." 1>&2 && return 1; }
  else
      sed -i'' -e 's/^;\([a-z_]*extension\)/\1/g' "${ini}" \
        && echo "> $ext ENABLED in ${ini}" \
        || { echo "> ERROR: failed to update ${ini} file ..." 1>&2 && return 1; }
  fi

  /usr/sbin/httpd -k graceful
  php -v
}


################################################################################
# Main
################################################################################
main()
{
  switchAction "$@"
}
main "${@:-}"

