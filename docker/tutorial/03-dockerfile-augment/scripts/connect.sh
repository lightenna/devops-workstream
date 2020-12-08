#!/usr/bin/env bash

# constants
IMAGE_NAME="nginx_augmented"
CONTAINER_NAME="my_nginx"

# connect to running container
docker exec -it ${CONTAINER_NAME} /bin/bash
