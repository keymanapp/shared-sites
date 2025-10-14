# shellcheck shell=bash
# Keyman is copyright (C) SIL Global. MIT License.

# Site repositories that run on Docker
export sites=(api.keyman.com help.keyman.com keyman.com keymanweb.com s.keyman.com website-local-proxy)
export repositories=("${sites[@]/#/keymanapp/}")
export site_targets=("${sites[@]/#/:}")
