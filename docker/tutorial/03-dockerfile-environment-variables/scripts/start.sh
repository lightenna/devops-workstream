#!/usr/bin/env bash

# change into the parent directory, if not there already
cwd="$(dirname $(dirname $(readlink -f "$0")))"
cd $cwd

# constants
IMAGE_NAME="dockenvvars"
CONTAINER_NAME="${IMAGE_NAME}"

# build new image
docker run -d --name ${CONTAINER_NAME} -p 3033:3032 -e "PORT=3032" ${IMAGE_NAME}:latest
