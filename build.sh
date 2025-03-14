#!/usr/bin/env bash
set -eu

readonly THIS_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
readonly THIS_SCRIPT_PATH="$(dirname "$THIS_SCRIPT")"

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

build_file_list