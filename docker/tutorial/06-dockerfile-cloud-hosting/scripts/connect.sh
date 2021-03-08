#!/usr/bin/env bash

# change into the parent directory, if not there already
cwd="$(dirname $(dirname $(readlink -f "$0")))"
cd $cwd

# constants
IMAGE_NAME="dockcloudhost"
CONTAINER_NAME="${IMAGE_NAME}"

# exec into the running container
docker exec -it ${CONTAINER_NAME} /bin/bash