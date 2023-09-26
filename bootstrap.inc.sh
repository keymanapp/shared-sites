# Shared infrastructure for websites

BOOTSTRAP_BUILDER="$(dirname "$BOOTSTRAP")/builder.inc.sh"

function _bootstrap_init() {
  # If builder.inc.sh is missing, download both it and bootstrap once more
  if [[ ! -f "$BOOTSTRAP_BUILDER" ]]; then
    curl -fs https://raw.githubusercontent.com/keymanapp/shared-sites/main/bootstrap.inc.sh -o "$BOOTSTRAP"
    curl -fs https://raw.githubusercontent.com/keymanapp/shared-sites/main/resources/builder.inc.sh -o "$BOOTSTRAP_BUILDER"
  fi
}


function bootstrap_configure() {
  # Re-download both bootstrap and builder.inc.sh
  rm -f "$BOOTSTRAP_BUILDER"
  _bootstrap_init

  # Load the new bootstrap before doing additional downloads
  source "$BOOTSTRAP"

  _bootstrap_configure_common
}

function _bootstrap_configure_common() {
  echo "TODO: download common folder"
}

# Test if resources need to be downloaded, in particular builder.inc.sh
_bootstrap_init
