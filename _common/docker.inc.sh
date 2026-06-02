# Common container functions.

function get_docker_image_id() {
  local IMAGE_NAME=$1
  echo "$($BUILDER_ENGINE images -q $IMAGE_NAME)"
}

function get_docker_container_id() {
  local CONTAINER_NAME=$1
  echo "$($BUILDER_ENGINE ps -a -q --filter ancestor=$CONTAINER_NAME)"
}

function stop_docker_container() {
  local IMAGE_NAME=$1
  local CONTAINER_NAME=$2

  local CONTAINER_ID=$(get_docker_container_id $CONTAINER_NAME)
  if [ ! -z "$CONTAINER_ID" ]; then
    $BUILDER_ENGINE container stop $CONTAINER_ID
  else
    builder_echo "No Docker container to stop"
  fi
}

function clean_docker_container() {
  local IMAGE_NAME=$1
  local CONTAINER_NAME=$2

  # Stop and cleanup Docker containers and images used for the site
  stop_docker_container $IMAGE_NAME $CONTAINER_NAME

  local CONTAINER_ID=$(get_docker_container_id $CONTAINER_NAME)
  if [ ! -z "$CONTAINER_ID" ]; then
    $BUILDER_ENGINE container rm $CONTAINER_ID
  else
    echo "No Docker container to clean"
  fi

  local IMAGE_ID=$(get_docker_image_id $IMAGE_NAME)
  if [ ! -z "$IMAGE_ID" ]; then
    $BUILDER_ENGINE rmi $IMAGE_NAME
  else
    echo "No Docker image to clean"
  fi
}

function _verify_vendor_is_not_folder() {
  if [ -d vendor ]; then
    builder_die "vendor/ folder exists. Remove and retry"
  fi
}

function build_docker_container() {
  local IMAGE_NAME=$1
  local CONTAINER_NAME=$2
  local BUILDER_CONFIGURATION="release"
  local FILE=
  local TARGET=.
  echo $CONTAINER_ENGINE
  if [[ $# -ge 3 ]]; then
    BUILDER_CONFIGURATION=$3
  fi
  if [[ $# -ge 4 ]]; then
    FILE="-f $4 "
  elif [[ "${CONTAINER_ENGINE}" == "docker" ]]; then
    FILE="-f Dockerfile "
  elif [[ "${CONTAINER_ENGINE}" == "podman" ]]; then
    FILE="-f Podmanfile "
  fi

  _verify_vendor_is_not_folder

  builder_echo "Building using $BUILDER_CONFIGURATION configuration"

  # Download docker image. --mount option requires BuildKit
  DOCKER_BUILDKIT=1 $BUILDER_ENGINE build -t $IMAGE_NAME --build-arg BUILDER_CONFIGURATION="${BUILDER_CONFIGURATION}" $FILE $TARGET
}

function start_docker_container() {
  local IMAGE_NAME=$1
  local CONTAINER_NAME=$2
  local CONTAINER_DESC=$3
  local HOST=$4
  local PORT=$5
  local BUILDER_CONFIGURATION="release"
  if [[ $# -eq 6 ]]; then
    BUILDER_CONFIGURATION=$6
  fi

  _verify_vendor_is_not_folder

  builder_echo "Starting using $BUILDER_CONFIGURATION configuration"

  if [[ $BUILDER_CONFIGURATION =~ debug ]]; then
    touch _control/debug
    rm -f _control/release
  else
    rm -f _control/debug
    touch _control/release
  fi

  local CONTAINER_ID=$(get_docker_container_id $CONTAINER_NAME)
  if [ ! -z "$CONTAINER_ID" ]; then
    builder_echo green "Container $CONTAINER_ID has already been started, listening on http://$HOST:$PORT"
    return 0
  fi

  # Start the Docker container
  if [ -z $(get_docker_image_id $IMAGE_NAME) ]; then
    builder_echo yellow "Docker container doesn't exist. Running \"./build.sh build\" first"
    "$THIS_SCRIPT" build
    builder_echo green "Docker container created successfully"
  fi

  if [ -z "${DOCKER_BINDING+x}" ]; then
    if [[ $OSTYPE =~ msys|cygwin ]]; then
      # Windows needs leading slashes for path
      DOCKER_BINDING="//$(pwd):/var/www/html/"
    else
      DOCKER_BINDING="$(pwd):/var/www/html/"
    fi
  fi

  ADD_HOST=
  if [[ $OSTYPE =~ linux-gnu ]]; then
    # Linux needs --add-host parameter
    ADD_HOST="--add-host host.docker.internal:host-gateway"
  fi

  $BUILDER_ENGINE run --rm -d -p $PORT:80 -v "${DOCKER_BINDING}" \
    -e S_KEYMAN_COM=localhost:$PORT_S_KEYMAN_COM \
    -e API_KEYMAN_COM=localhost:$PORT_API_KEYMAN_COM \
    --name $CONTAINER_DESC \
    ${ADD_HOST} \
    $CONTAINER_NAME

  # Skip if link already exists
  if [ ! -L vendor ] && [ -f composer.json ]; then
    # Create link to vendor/ folder
    CONTAINER_ID=$(get_docker_container_id $CONTAINER_NAME)
    if [ -z "$CONTAINER_ID" ]; then
      builder_die "Docker container appears to have failed to start in order to create link to vendor/"
    fi

    $BUILDER_ENGINE exec -i $CONTAINER_ID sh -c "ln -s /var/www/vendor vendor && chown -R www-data:www-data vendor"
  fi

  # after starting container, we want to run an init script if it is present
  if [ -f resources/init-container.sh ]; then
    CONTAINER_ID=$(get_docker_container_id $CONTAINER_NAME)
    if [ -z "$CONTAINER_ID" ]; then
      builder_die "Docker container appears to have failed to start in order to run init-container.sh script"
    fi

    cmd="./resources/init-container.sh ${BUILDER_CONFIGURATION}"
    builder_echo green "cmd is ${cmd}"
    $BUILDER_ENGINE exec -i $CONTAINER_ID sh -c "${cmd}"
  fi

  builder_echo green "Listening on http://$HOST:$PORT"
}

# Returns 0 if the specified container engine is available, 1 otherwise
_is_container_engine() {
  local engine="$1"
  if command -v "$engine" >/dev/null 2>&1; then
    return 0
  else
    return 1
  fi
}

_get_container_engine() {
  export BUILDER_ENGINE
  if _is_container_engine "docker"; then
    BUILDER_ENGINE="docker"
  elif _is_container_engine "podman"; then
    BUILDER_ENGINE="podman"
  else
    builder_die "No supported container engine found. Please install Docker or Podman to run containerized builds."
  fi
}

################################################################################
# Final initialization
################################################################################

_get_container_engine
builder_echo "Using container engine: $BUILDER_ENGINE"