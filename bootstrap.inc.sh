# Shared infrastructure for websites

readonly BOOTSTRAP_BUILDER="$(dirname "$BOOTSTRAP")/builder.inc.sh"

function _bootstrap_init() {
  # If builder.inc.sh is missing, download it
  if [[ ! -f "$BOOTSTRAP_BUILDER" ]]; then
    curl -fs https://raw.githubusercontent.com/keymanapp/shared-sites/main/resources/builder.inc.sh > "$BOOTSTRAP_BUILDER" || (rm -f "$BOOTSTRAP_BUILDER" && exit 1)
  fi
}


function bootstrap_configure() {
  # Download latest version of bootstrap before running common configuration
  curl -fs https://raw.githubusercontent.com/keymanapp/shared-sites/main/bootstrap.inc.sh > "$BOOTSTRAP.tmp" || (rm -f "$BOOTSTRAP.tmp" && exit 1)
  mv -f "$BOOTSTRAP.tmp" "$BOOTSTRAP"

  # With the new bootstrapper, we'll re-download builder.inc.sh
  rm -f "$BOOTSTRAP_BUILDER"

  . "$BOOTSTRAP"

  _bootstrap_init
  _bootstrap_configure_common
}

function _bootstrap_configure_common() {
  echo "TODO: download common folder"
}

# Test if resources need to be downloaded, in particular builder.inc.sh
_bootstrap_init
