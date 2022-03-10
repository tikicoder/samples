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

user_name=$(whoami)
user_home="/home/${user_name}"
user_aliases="${user_home}/.bashrc_alias"

mkdir -p "${user_home}/.local/bin"

tmp_directory=$1
docker_groupid=$

mkdir -p $tmp_directory
pushd $tmp_directory

if [ ! -f "${user_home}/.bashrc_alias" ]; then
  touch "${user_home}/.bashrc_alias"
fi

if [ $(grep -ic "\$HOME/.bashrc_alias" "${user_home}/.bashrc" ) -lt 1  ]; then
  echo "" >> "${user_home}/.bashrc"
  cat >> "${user_home}/.bashrc" << EOF
if [ -f "\$HOME/.bashrc_alias" ] ; then
   . "\$HOME/.bashrc_alias"
fi
EOF
fi

# https://docs.docker.com/network/bridge/#differences-between-user-defined-bridges-and-the-default-bridge
# using --network host while work to figure the bridge config out
if [ $(grep -ic "alias aws=" "${user_home}/.bashrc_alias" ) -lt 1  ]; then
  mkdir -p "~/.docker_containers/aws"
  # https://hub.docker.com/r/amazon/aws-cli
  echo "alias aws='docker run --network host --rm -it -v ~/.docker_containers/aws:/root/.aws -v $(pwd):/aws amazon/aws-cli:latest'" >> "${HOME}/.bashrc_alias"
fi

if [ $(grep -ic "alias az=" "${user_home}/.bashrc_alias" ) -lt 1  ]; then
  mkdir -p "~/.docker_containers/azure"
  mkdir -p "~/.docker_containers/Azure"
  # https://hub.docker.com/_/microsoft-azure-cli
  echo "alias az='docker run --network host --rm -it -v ${user_home}/.ssh:/root/.ssh -v ~/.docker_containers/azure:/root/.azure -v ~/.docker_containers/Azure:/root/.Azure mcr.microsoft.com/azure-cli:latest /usr/local/bin/az'" >> "${HOME}/.bashrc_alias"
  echo "alias az_update='docker pull mcr.microsoft.com/azure-cli'"
fi

. "$user_home/.bashrc"
. "$user_home/.bashrc_alias"

az --version
aws --version

popd

