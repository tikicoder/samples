#!/bin/bash

# https://hub.docker.com/_/rockylinux

# This is hardcoded to ensure the other scripts would work
download_version="8.5" 

docker run --name rocky-container "rockylinux/rockylinux:$download_version"
image_id=$( docker image ls | grep -i "rockylinux/rockylinux" | grep -i 'latest' | head -1 | awk '{print $3}')

docker export rocky-container | gzip > "rocky-container.${download_version}.tar.gz"

docker container ls --all | grep -i "ame rocky-container" | awk '{print $1}' | xargs
docker rm
docker rmi $image_id
