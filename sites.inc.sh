# shellcheck shell=bash
# Keyman is copyright (C) SIL Global. MIT License.

# Site repositories that run on Docker

# The following sites are most commonly used by dev team -- so run only those by default
export common_sites=(api.keyman.com help.keyman.com keyman.com keymanweb.com s.keyman.com website-local-proxy)
export sites=("${common_sites[@]}" status.keyman.com r.keymanweb.com tavultesoft.com)
export repositories=("${sites[@]/#/keymanapp/}")
export site_targets=("${sites[@]/#/:}")
