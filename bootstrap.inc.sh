# Shared infrastructure for websites

set -eu

# BOOTSTRAP variable is defined in the standard site prolog.
# 1. Update BOOTSTRAP_VERSION to the published tag or commitish to use
# 2. Update BOOTSTRAP path as necessary
#
#    ## START STANDARD SITE BUILD SCRIPT INCLUDE
#    readonly THIS_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
#    readonly BOOTSTRAP="$(dirname "$THIS_SCRIPT")/resources/bootstrap.inc.sh"
#    readonly BOOTSTRAP_VERSION=v0.3
#    [ -f "$BOOTSTRAP" ] && source "$BOOTSTRAP" || source <(curl -fs https://raw.githubusercontent.com/keymanapp/shared-sites/$BOOTSTRAP_VERSION/bootstrap.inc.sh)
#    ## END STANDARD SITE BUILD SCRIPT INCLUDE

#
# Sanity checks on start
#

if [[ -z ${BOOTSTRAP+x} ]]; then
  echo "FATAL: \$BOOTSTRAP must be defined according to standard site build.sh script prolog"
  exit 2
fi

if [[ -z ${BOOTSTRAP_VERSION+x} ]]; then
  echo "FATAL: \$BOOTSTRAP_VERSION must be defined according to standard site build.sh script prolog"
  exit 2
fi

if [[ -z ${THIS_SCRIPT+x} ]]; then
  echo "FATAL: \$THIS_SCRIPT must be defined according to standard site build.sh script prolog"
  exit 2
fi

#
# Define globals (if not already defined)
#

if [[ -z ${BOOTSTRAP_ROOT+x} ]]; then
  readonly BOOTSTRAP_ROOT="$(dirname "$BOOTSTRAP")/.."
fi

if [[ -z ${BOOTSTRAP_CURRENT_VERSION_FILE+x} ]]; then
  readonly BOOTSTRAP_CURRENT_VERSION_FILE="$(dirname "$BOOTSTRAP")/.bootstrap-version"
fi

if [[ -z ${BOOTSTRAP_REGISTRY+x} ]]; then
  readonly BOOTSTRAP_REGISTRY="$(dirname "$BOOTSTRAP")/.bootstrap-registry"
fi

#
# Helper function to download a file from the shared-sites repository 'main' branch
#
function _bootstrap_download() {
  local remote_file="$1"
  local local_file="$2"
  _bootstrap_echo "  Downloading $remote_file"

  _bootstrap_try_multiple_times curl -H "Cache-Control: no-cache" -f --no-progress-meter "https://raw.githubusercontent.com/keymanapp/shared-sites/$BOOTSTRAP_VERSION/$remote_file" -o "$local_file" || (
    _bootstrap_echo "FATAL: Failed to download $remote_file"
    _bootstrap_echo "Note: removing $BOOTSTRAP_CURRENT_VERSION_FILE to force bootstrap on next run"
    rm -f "$BOOTSTRAP_CURRENT_VERSION_FILE"
    exit 3
  ) || exit $?

}

function _bootstrap_echo() {
  echo "[bootstrap] $*"
}

#
# Initialize required files, including downloading common, if those files are
# not present. Note that on first run bootstrap.inc.sh will be downloaded twice,
# once by the prolog, and again in _bootstrap_init, but as this is a low-cost
# operation, it makes the build script prolog cleaner to do it this way.
#
# This will be called on first run on a clean repo, and should also be called
# on `build.sh configure`.
#
function bootstrap_configure() {
  _bootstrap_echo "Bootstrap starting"
  _bootstrap_download bootstrap.inc.sh "$BOOTSTRAP"

  # Record the version we downloaded -- before we re-source the script!
  echo $BOOTSTRAP_VERSION > "$BOOTSTRAP_CURRENT_VERSION_FILE"

  # Load the new bootstrap before doing additional downloads. The bootstrap
  # include script has been designed to cope with being run multiple times;
  # this ensures that the latest version of _bootstrap_configure_common is
  # run.
  source "$BOOTSTRAP"

  _bootstrap_configure_common

  _bootstrap_echo "Bootstrap complete"
}

#
# Download all files in _common, removing existing files
#
function _bootstrap_configure_common() {
  _bootstrap_echo "Downloading bootstrap registry to $BOOTSTRAP_REGISTRY"
  _bootstrap_download .bootstrap-registry "$BOOTSTRAP_REGISTRY"

  local BOOTSTRAP_LOCAL_COMMON="$BOOTSTRAP_ROOT/_common"

  _bootstrap_echo "Downloading _common files"

  rm -rf "$BOOTSTRAP_LOCAL_COMMON"
  mkdir -p "$BOOTSTRAP_LOCAL_COMMON"

  local filename
  local basefile
  local cdnfile

  while read filename; do
    read -r basefile cdnfile <<<"$filename"
    mkdir -p "$BOOTSTRAP_LOCAL_COMMON/$(dirname "$basefile")"
    _bootstrap_download "_common/$basefile" "$BOOTSTRAP_LOCAL_COMMON/$basefile"

    # CDN hashed filename support
    if [[ ! -z $cdnfile ]]; then
      mkdir -p "$BOOTSTRAP_LOCAL_COMMON/$(dirname "$cdnfile")"
      _bootstrap_download "_common/$cdnfile" "$BOOTSTRAP_LOCAL_COMMON/$cdnfile"
    fi
  done < "$BOOTSTRAP_REGISTRY"

  _bootstrap_echo "All _common files downloaded"
}

#
# Check the bootstrap files against the .bootstrap-version file
#
function _bootstrap_new_version_requested() {
  if [[ ! -f $BOOTSTRAP_CURRENT_VERSION_FILE ]]; then
    # unknown version, version file doesn't exist, should rebuild
    return 0
  fi

  if [[ "$(cat "$BOOTSTRAP_CURRENT_VERSION_FILE")" != "$BOOTSTRAP_VERSION" ]]; then
    # version is different, should rebuild
    return 0
  fi

  return 1
}

# Test if resources need to be downloaded
if [[ ! -f "$BOOTSTRAP" ]] || _bootstrap_new_version_requested; then
  _bootstrap_echo "Bootstrap required"
  bootstrap_configure
fi

# Finally, we need to run builder.inc.sh, if it hasn't already been run
if [[ -z ${THIS_SCRIPT_PATH+x} ]] && [[ -f "$(dirname "$THIS_SCRIPT")/_common/builder.inc.sh" ]]; then
  source "$(dirname "$THIS_SCRIPT")/_common/builder.inc.sh"

  # Bootstrapped scripts always run from their own folder (probably $REPO_ROOT),
  # but only do this on first-run, not if re-sourced with bootstrap_configure
  cd "$THIS_SCRIPT_PATH"
fi


#
# Re-runs the specified command-line instruction up to 5 times should it fail, waiting
# 10 seconds between each attempt.  No re-runs are attempted after successful commands.
#
# Note: from shellHelperFunctions.sh in keymanapp/keyman
#
# ### Usage
#   _bootstrap_try_multiple_times command [param1 param2...]
#
# ### Parameters
#   1: $@         command-line arguments
_bootstrap_try_multiple_times ( ) {
  __bootstrap_try_multiple_times 0 "$@"
}

# $1  The current retry count
# $2+ (everything else) the command to retry should it fail
__bootstrap_try_multiple_times ( ) {
  local RETRY_MAX=5
  # in seconds
  local RETRY_MIN_WAIT=10

  local retryCount=$1
  shift

  if (( "$retryCount" == "$RETRY_MAX" )); then
    echo 2>&1 "Retry limit of $RETRY_MAX attempts reached."
    return 1
  fi

  retryCount=$(( $retryCount + 1 ))

  if (( $retryCount != 1 )); then
    echo 2>&1 "Delaying $RETRY_MIN_WAIT seconds before attempt $retryCount:"
    echo 2>&1 "    $@"
    sleep $RETRY_MIN_WAIT
  fi

  local code=0
  "$@" || code=$?
  if (( $code != 0 )); then
    echo 2>&1 "Command failed with error $code"
    __bootstrap_try_multiple_times $retryCount "$@"
  fi
}
