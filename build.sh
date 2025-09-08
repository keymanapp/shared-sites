#!/usr/bin/env bash
# Keyman is copyright (C) SIL Global. MIT License.

## START STANDARD BUILD SCRIPT INCLUDE
# adjust relative paths as necessary
THIS_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
. "${THIS_SCRIPT%/*}/_common/builder.inc.sh"
## END STANDARD BUILD SCRIPT INCLUDE

. "$THIS_SCRIPT_PATH/sites.inc.sh"

builder_describe "Build common site resources and coordinate sites" \
  "build-files        Build list of assets for sharing" \
  \
  "clone              Clone keyman website repositories" \
  "pull               Switch to master and pull latest changes to keyman website repositories, DELETES MERGED BRANCHES" \
  "configure          Configure keyman website repositories" \
  "clean              Clean keyman website repositories" \
  "build              Build docker images for keyman website repositories" \
  "start              Start Docker containers for keyman website repositories" \
  "stop               Stop Docker containers for keyman website repositories" \
  "test               Test keyman website repositories in Docker" \
  \
  ":shared-sites      This repo, for build-files" \
  "${site_targets[@]}"

builder_parse "$@"

cd "$THIS_SCRIPT_PATH"

#
# Rebuilds .bootstrap-registry and copies assets from /assets into
# /_common/assets. Note that all existing files in /_common/assets will be
# removed prior to the assets being copied in again. This will generate two
# files for each asset in the /_common/assets folder: a copy of the original
# file from /assets, and a second copy which has a sha1 hash of the contents of
# the file embedded in the filename, for cache-busting purposes.
#
# TODO: we could tweak the asset management in the future to use symbolic links.
#
build_file_list() {
  local regtemp="$(mktemp)"
  local filename

  rm -f .bootstrap-registry
  rm -rf _common/assets

  # Find all asset files in /assets and copy them into the /_common/assets
  # folder along with their sha1 hash
  find assets -type f -printf '%P\n' > "$regtemp"

  while read filename; do
    local base="$(basename "$filename")"
    local dir="$(dirname "$filename")"

    local file="${base%.*}"
    local ext="${base##*.}"

    sha1=$(sha1sum "assets/$filename" | cut -d' ' -f 1 -)
    local sha1filename="$dir/$file.$sha1.$ext"

    mkdir -p "_common/assets/$dir"
    cp "assets/$filename" "_common/assets/$sha1filename"
    cp "assets/$filename" "_common/assets/$filename"
    echo "assets/$filename assets/$sha1filename" >> .bootstrap-registry
  done < "$regtemp"

  rm -f "$regtemp"

  # Add other non-asset (server-side) shared files
  find _common -type f ! -name README.md ! -path '_common/assets/*'  -printf '%P\n' >> .bootstrap-registry
}

builder_run_action        build-files:shared-sites     build_file_list

# Site actions

site_clone() {
  local site=$1
  cd "$THIS_SCRIPT_PATH/.."
  if [[ ! -d $site ]]; then
    git clone https://github.com/keymanapp/$site
  fi
}

site_pull() {
  local site=$1
  cd "$THIS_SCRIPT_PATH/../$site"
  # note: this will die if there are changes that prevent branch switch
  git switch master
  git pull -p
  # delete any upstream-tracked merged/deleted branches, ignore errors where
  # local changes prevent deletion. This keeps the repo reasonably up-to-date,
  # without any risk of damage
  (git for-each-ref --format '%(refname:short) %(upstream:track)' | grep '\[gone\]' | cut -d' ' -f 1 - | xargs -r git branch -d) || true
}

site_action() {
  local action=$1
  local site=$2
  cd "$THIS_SCRIPT_PATH/../$site"
  ./build.sh $action
}

for action in clone pull; do
  for site in ${sites[@]}; do builder_run_action $action:$site site_$action $site; done
done

for action in configure clean build start stop test; do
  for site in ${sites[@]}; do builder_run_action $action:$site site_action $action $site; done
done
