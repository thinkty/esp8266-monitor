#!/bin/bash

#------------------------------------------------------------------------------
# This script builds the docker image using the Dockerfile and runs the image
# in a container with the given name.
#------------------------------------------------------------------------------

set -eu

# Program Arguments
DOCKER_BUILD_TAG=dabe
DOCKER_IMAGE_TAG=dabe
DOCKER_REBUILD=false
DOCKER_CONTAINER_NAME=dabec

#------------------------------------------------------------------------------
# @brief Display usage of the script
#------------------------------------------------------------------------------
usage() {
  echo "
Usage: $0 [-i|--image NAME] [-c|--container NAME] [-b|--build]

Options:
    -i, --image NAME
        Name of the docker image to be built/used. Default value is '$DOCKER_IMAGE_TAG'
    -c, --container NAME
        Name of the docker container to be used. Default value is '$DOCKER_CONTAINER_NAME'
    -b, --build
        Force re-build. Even if there exists an image with the given tag name, build the docker image again.
" > /dev/stderr
}

OPTIONS=$(getopt -o "i:c:bh" --long "image:,container:,build,help" -n $0 -- "$@")
eval set -- "$OPTIONS"

# Parse arguments if given
while true; do
    case "$1" in
        -i | --image)
            DOCKER_IMAGE_TAG="$2"
            shift 2
            ;;
        -c | --container)
            DOCKER_CONTAINER_NAME="$2"
            shift 2
            ;;
        -b | --build)
            DOCKER_REBUILD=true
            shift
            ;;
        --)
            shift
            break
            ;;
        *)
            usage
            exit 1
            ;;
    esac
done

# Check if docker is intalled
if ! command -v docker > /dev/null 2>&1; then
    echo "Error: docker command not found."
    exit 1
fi

# Check if Dockerfile exists
if [ ! -f ./Dockerfile ]; then
    echo "Error: Dockerfile not found."
    exit 1
fi

# Check if docker image is already built or needs rebuilding
if [ -z "$(docker images -q $DOCKER_IMAGE_TAG 2> /dev/null)" ] || [ "$DOCKER_REBUILD" = true ]; then

    # Build docker image with VOL_PATH set as current project directory
    docker build --no-cache --tag=$DOCKER_BUILD_TAG --build-arg VOL_PATH=$PWD . || exit 1
fi

# Create and run a docker container with the specified image
docker run --name=${DOCKER_CONTAINER_NAME} --rm -i -t -v ${PWD}:${PWD} -v /etc/passwd:/etc/passwd:ro -v /etc/group:/etc/group:ro --user $(id -u):$(id -g) ${DOCKER_IMAGE_TAG} || exit 1

exit 0
