#!/usr/bin/env bash
set -eu

readonly THIS_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
readonly THIS_SCRIPT_PATH="$(dirname "$THIS_SCRIPT")"

find "$THIS_SCRIPT_PATH/_common" -type f '!' '-name' 'README.md' -printf '%P\n' > .bootstrap-registry
