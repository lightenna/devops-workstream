#!/usr/bin/env bash

# change into the parent directory, if not there already
cwd="$(dirname $(dirname $(readlink -f "$0")))"
cd $cwd

# constants
IMAGE_NAME="nginx_augmented"
CONTAINER_NAME="my_nginx"

# build new image
docker run -d --name ${CONTAINER_NAME} -p 8081:8080 ${IMAGE_NAME}:latest
