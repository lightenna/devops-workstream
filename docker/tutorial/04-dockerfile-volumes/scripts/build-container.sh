#!/usr/bin/env bash

# change into the parent directory, if not there already
cwd="$(dirname $(dirname $(readlink -f "$0")))"
cd $cwd

# constants
IMAGE_NAME="dockvols"

# stop and remove container if running
docker rm --force ${IMAGE_NAME}

# scrub image if present
docker rmi --force ${IMAGE_NAME}

# build new image
docker build -t ${IMAGE_NAME}:latest -f ./Dockerfile .
