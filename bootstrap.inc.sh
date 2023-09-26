# Shared infrastructure for websites

set -eu

# BOOTSTRAP variable is defined in the standard site prolog:
#
#    ## START STANDARD BUILD SCRIPT INCLUDE
#    # adjust relative paths as necessary
#    readonly THIS_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
#    readonly BOOTSTRAP="$(dirname "$THIS_SCRIPT")/resources/bootstrap.inc.sh"
#    [ -f "$BOOTSTRAP" ] && source "$BOOTSTRAP" || source <(curl -fs https://raw.githubusercontent.com/keymanapp/shared-sites/main/bootstrap.inc.sh)
#    ## END STANDARD BUILD SCRIPT INCLUDE

#
# Sanity checks on start
#

if [[ -z ${BOOTSTRAP+x} ]]; then
  echo "FATAL: \$BOOTSTRAP must be defined according to standard site build.sh script prolog"
  exit 2
fi

if [[ -z ${THIS_SCRIPT+x} ]]; then
  echo "FATAL: \$THIS_SCRIPT must be defined according to standard site build.sh script prolog"
  exit 2
fi

#
# Define globals (if not already defined)
#

if [[ -z ${BOOTSTRAP_BUILDER+x} ]]; then
  readonly BOOTSTRAP_BUILDER="$(dirname "$BOOTSTRAP")/builder.inc.sh"
fi

if [[ -z ${BOOTSTRAP_ROOT+x} ]]; then
  readonly BOOTSTRAP_ROOT="$(dirname "$BOOTSTRAP")/.."
fi

#
# Helper function to download a file from the shared-sites repository 'main' branch
#
function _bootstrap_download() {
  local remote_file="$1"
  local local_file="$2"
  curl -fs "https://raw.githubusercontent.com/keymanapp/shared-sites/main/$remote_file" -o "$local_file"
}

#
# Initialize required files, including downloading common, if those files are
# not present. Note that on first run bootstrap.inc.sh will be downloaded twice,
# once by the prolog, and again in _bootstrap_init, but as this is a low-cost
# operation, it makes the build script prolog cleaner to do it this way.
#
function _bootstrap_init() {
  # If builder.inc.sh is missing, download both it and bootstrap once more
  if [[ ! -f "$BOOTSTRAP_BUILDER" ]]; then
    # Note that builder.inc.sh is a special case; it could be part of
    # _common but we are using it as our signal for whether the repo needs
    # additional files
    _bootstrap_download bootstrap.inc.sh         "$BOOTSTRAP"
    _bootstrap_download resources/builder.inc.sh "$BOOTSTRAP_BUILDER"

    # Load the new bootstrap before doing additional downloads. The bootstrap
    # include script has been designed to cope with being run multiple times;
    # this ensures that the latest version of _bootstrap_configure_common is
    # run.
    source "$BOOTSTRAP"

    _bootstrap_configure_common
  fi
}

#
# Update shared files -- call this on `build.sh configure`
#
function bootstrap_configure() {
  # Deleting builder.inc.sh will force a re-download of bootstrap.inc.sh
  # and builder.inc.sh, and everything else
  rm -f "$BOOTSTRAP_BUILDER"
  _bootstrap_init
}

#
# Download all files in _common, removing existing files
#
function _bootstrap_configure_common() {
  local BOOTSTRAP_COMMON="$BOOTSTRAP_ROOT/_common"
  local COMMON_FILES=(
    docker.inc.sh
    keyman-local-ports.inc.sh
    JsonApiFailure.php
    KeymanHosts.php
    KeymanSentry.php
    MarkdownHost.php
  )
  local common_file=

  echo "Downloading _common files"
  rm -rf "$BOOTSTRAP_COMMON"
  mkdir -p "$BOOTSTRAP_COMMON"

  for common_file in "${COMMON_FILES[@]}"; do
    echo "  Downloading $common_file..."
    _bootstrap_download "_common/$common_file" "$BOOTSTRAP_COMMON/$common_file"
  done

  echo "All _common files downloaded"
}

# Test if resources need to be downloaded, in particular builder.inc.sh
_bootstrap_init

# Finally, we need to run builder.inc.sh, if it hasn't already been run
if [[ -z ${THIS_SCRIPT_PATH+x} ]]; then
  source "$BOOTSTRAP_BUILDER"
fi
