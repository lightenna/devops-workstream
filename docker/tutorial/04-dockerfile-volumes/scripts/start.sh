#!/usr/bin/env bash

# change into the parent directory, if not there already
cwd="$(dirname $(dirname $(readlink -f "$0")))"
cd $cwd

# constants
IMAGE_NAME="dockvols"
CONTAINER_NAME="${IMAGE_NAME}"

# build new image
docker run -d --name ${CONTAINER_NAME} \
  -p 8081:8080 \
  -v ${cwd}/configuration/nginx.conf:/etc/nginx/nginx.conf \
  -v ${cwd}/example_website:/www/data \
  ${IMAGE_NAME}:latest
