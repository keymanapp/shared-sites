# shellcheck shell=bash
#
# Keyman is copyright (C) SIL Global. MIT License.
#
# Shared test functions for PHP lint, unit test, and general broken link checks
#

# Record the start time for unit tests for later log review
function do_test_record_start_time() {
  TEST_START_TIME=$(date -Is -u)
}

# Run unit tests through phpunit
#
# Parameters
# 1: CONTAINER     container_desc to run on
#
function do_test_unit_tests() {
  local CONTAINER="$1"
  docker exec "${CONTAINER}" sh -c "vendor/bin/phpunit --testdox ${builder_extra_params[*]}"
}

# Lint .php files for obvious errors
#
# Parameters
# 1: CONTAINER     container_desc to run on
#
function do_test_lint() {
  local CONTAINER="$1"
  docker exec "${CONTAINER}" sh -c "find . -name '*.php' | grep -v '/vendor/' | xargs -n 1 -d '\\n' php -l"
}

## Check links on live local server using linkinator
#
# Parameters
# 1:       baseURL     the top level URL for the site
# 2:       testPath    path under baseURL to start testing, e.g. /
# 3[,4..]: skipPaths   list of paths (under baseURL) to skip crawling, optional
#
function do_test_links() {
  local baseURL="$1"
  local testPath="$2"
  shift 2
  local skipPaths=("$@")
  local skip skipParams=()

  for skip in "${skipPaths[@]}"; do
    skipParams+=(--skip "^${baseURL}${skip}")
  done

  npx https://github.com/keymanapp/linkinator \
    "${baseURL}${testPath}" \
    --clean-urls \
    --concurrency 50 \
    --format json \
    --output-filename linkinator-results.json \
    --skip "^(?!${baseURL})" \
    "${skipParams[@]}" \
    --recurse \
    --redirects verify \
    --retry-errors \
    --root-path "${baseURL}"
}

# Print summary of results from linkinator
function do_test_print_link_report() {
  echo ----------------------------------------------------------------------
  echo Link check summary
  echo ----------------------------------------------------------------------
  # Emit full JSON detail for broken links (may not be necessary)
  jq '.links[] | select(.state != "OK")' < linkinator-results.json
  echo
  echo
  # Emit a summary report
  jq -r '.links[] | select(.state != "OK") | "\(.state)[\(.status)]: \(.parent)   -->   \(.url)"' < linkinator-results.json
}

# Scan logs recorded on container since start of tests to find any reported PHP
# errors (note, depends on '[php#:xxxx]' marker string, where # = 7 for PHP7, omitted for PHP8)
#
# Parameters
# 1: CONTAINER     container_desc to run on
#
function do_test_print_container_error_logs() {
  local CONTAINER="$1"
  if docker container logs "${CONTAINER}" --since "${TEST_START_TIME}" 2>&1 | grep -qP '\[php7?:(error|warn|notice)\]'; then
    echo 'PHP reported errors or warnings:'
    docker container logs "${CONTAINER}" --since "${TEST_START_TIME}" 2>&1 | grep -P '\[php7?:(error|warn|notice)\]'
    return 1
  else
    echo 'No PHP errors found'
    return 0
  fi
}
