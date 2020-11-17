#!/usr/bin/env bash

# change into the parent directory, if not there already
cwd="$(dirname $(dirname $(readlink -f "$0")))"
cd $cwd

# constants
IMAGE_NAME="testlike"

# build new image
docker run -d --name ${IMAGE_NAME} -p 3031:3030 ${IMAGE_NAME}:latest
