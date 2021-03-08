#!/usr/bin/env bash

# change into the parent directory, if not there already
cwd="$(dirname $(dirname $(readlink -f "$0")))"
cd $cwd

# constants
IMAGE_NAME="dockcloudhost"
CONTAINER_NAME="${IMAGE_NAME}"
ACR_TARGET="acr8conhost8dvw.azurecr.io"

# stop and remove container if running
docker rm --force ${CONTAINER_NAME}

# scrub local image if present
docker rmi --force ${ACR_TARGET}/${IMAGE_NAME}
