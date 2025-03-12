#!/usr/bin/env bash
set -eu

readonly THIS_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
readonly THIS_SCRIPT_PATH="$(dirname "$THIS_SCRIPT")"

cd "$THIS_SCRIPT_PATH"

build_file_list() {
  local regtemp="$(mktemp)"
  local filename

  rm -f .bootstrap-registry
  rm -rf _common/assets

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

  # Add other non-asset shared files
  find _common -type f ! -name README.md ! -path '_common/assets/*'  -printf '%P\n' >> .bootstrap-registry
}

build_file_list