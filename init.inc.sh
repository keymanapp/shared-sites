# Initialize the shared-sites builder script; this matches build env detected in
# bootstrap.inc.sh

# Get the site BUILDER_TIER and use that to determine builder script environment
if [[ ! -z ${KEYMANHOSTS_TIER+x} ]]; then
  BUILDER_TIER="${KEYMANHOSTS_TIER}"
elif [[ -f "$(dirname "$THIS_SCRIPT")/tier.txt" ]]; then
  BUILDER_TIER=$(cat "$(dirname "$THIS_SCRIPT")/tier.txt")
else
  BUILDER_TIER=TIER_DEVELOPMENT
fi

if [[ "$BUILDER_TIER" == TIER_DEVELOPMENT ]]; then
  export KEYMAN_VERSION_ENVIRONMENT=local
fi

. "${THIS_SCRIPT%/*}/_common/builder.inc.sh"
