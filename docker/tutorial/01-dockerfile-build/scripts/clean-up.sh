#!/usr/bin/env bash

# change into the parent directory, if not there already
cwd="$(dirname $(dirname $(readlink -f "$0")))"
cd $cwd

# constants
IMAGE_NAME="testlike"
CONTAINER_NAME="${IMAGE_NAME}"

# stop and remove container if running
docker rm --force ${CONTAINER_NAME}
