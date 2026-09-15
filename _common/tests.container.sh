#!/bin/bash
#
# Keyman is copyright (C) SIL Global. MIT License.
#
# Scripts to run in container for link tests -- capture all PHP messages emitted
# when each page is visited by the link checker, and report on errors
#

set -eu

if [[ ${BUILDER_PLATFORM-x} != docker ]]; then
  echo tests.container.sh should run only in the Docker container context
  exit 1
fi

if [ $# -lt 1 ]; then
  echo "usage: $0 setup|report|cleanup"
  exit 65
fi

ERROR_LOG=/tmp/php_errors.log

if [ "$1" == "setup" ]; then
  cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
  echo "error_log = $ERROR_LOG" >> /usr/local/etc/php/php.ini
  # note: apache restart must run from docker host
  rm -f $ERROR_LOG
elif [ "$1" == "report" ]; then
  if [ -f $ERROR_LOG ]; then
    cat $ERROR_LOG
    exit 1
  fi
elif [ "$1" == "cleanup" ]; then
  cp /usr/local/etc/php/php.ini-development /usr/local/etc/php/php.ini
  # note: apache restart must run from docker host
else
  echo "Invalid parameter"
  exit 65
fi

exit 0