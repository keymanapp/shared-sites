#!/usr/bin/env bash
set -eu

readonly THIS_SCRIPT="$(readlink -f "${BASH_SOURCE[0]}")"
readonly THIS_SCRIPT_PATH="$(dirname "$THIS_SCRIPT")"

cd "$THIS_SCRIPT_PATH"

build_file_list() {
  local regtemp="$(mktemp)"
  local filename


  rm -f .bootstrap-registry
  rm -rf _common/cdn

  find _common -type f '!' -name README.md -printf '%P\n' > "$regtemp"

  while read filename; do
    local base="$(basename "$filename")"
    local dir="$(dirname "$filename")"

    if [[ "$dir" =~ ^assets/ ]]; then
      local file="${base%.*}"
      local ext="${base##*.}"

      sha1=$(sha1sum "_common/$filename" | cut -d' ' -f 1 -)
      local sha1filename="$dir/$file.$sha1.$ext"

      mkdir -p "_common/cdn/$dir"
      cp "_common/$filename" "_common/cdn/$sha1filename"
      echo "$filename $sha1filename" >> .bootstrap-registry
    else
      echo "$filename" >> .bootstrap-registry
    fi
  done < "$regtemp"

  rm -f "$regtemp"
}

build_file_list