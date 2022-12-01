#!/bin/bash

# https://hub.docker.com/_/rockylinux

# This is hardcoded to ensure the other scripts would work

#!/bin/bash
if [ ! $(command -v "realpath") ]; then
    realpath() {
    OURPWD=$PWD
    cd "$(dirname "$1")"
    LINK=$(readlink "$(basename "$1")")
    while [ "$LINK" ]; do
        cd "$(dirname "$LINK")"
        LINK=$(readlink "$(basename "$1")")
    done
    REALPATH="$PWD/$(basename "$1")"
    cd "$OURPWD"
    echo "$REALPATH"
    }
fi

full_path=$(realpath $0)
dir_path=$(dirname $full_path)
parent_path=$(realpath "${dir_path}/../")
root_path=$parent_path

download_version="latest" 
if [ $# -gt 0 ]; then
  download_version="${@:${#@}:${#@}}"
fi


container_name="rocky-container"
container_name_full="$container_name-$download_version"
docker run --name "${container_name_full}" "rockylinux/rockylinux:$download_version"
image_id=$( docker image ls | grep -i "rockylinux/rockylinux" | grep -i $download_version | head -1 | awk '{print $3}')

docker export $container_name_full | gzip > "${dir_path}/rocky-container.${download_version}.tar.gz"

docker container ls --all | grep -i $container_name | awk '{print $1}' | xargs docker rm
docker rmi $image_id
