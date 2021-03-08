#!/usr/bin/env bash

# change into the parent directory, if not there already
cwd="$(dirname $(dirname $(readlink -f "$0")))"
cd $cwd

# constants
IMAGE_NAME="dockcloudhost"
ACR_TARGET="acr8conhost8dvw.azurecr.io"

# stop and remove container if running
docker rm --force ${IMAGE_NAME}

# scrub local image if present
docker rmi --force ${ACR_TARGET}/${IMAGE_NAME}

# build new image and push to ACR (requires previous login)
docker build -t ${ACR_TARGET}/${IMAGE_NAME}:latest --build-arg SERVICENAME=${IMAGE_NAME} -f ./Dockerfile .
docker push ${ACR_TARGET}/${IMAGE_NAME}