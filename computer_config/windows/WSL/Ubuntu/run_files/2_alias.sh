#!/bin/bash
set -e

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
user_home="${HOME}"
user_aliases="${user_home}/.bashrc_alias"

mkdir -p "${HOME}/.local/bin"

tmp_directory=$1
docker_groupid=$

mkdir -p $tmp_directory
pushd $tmp_directory

if [ ! -f "${HOME}/.bashrc_alias" ]
  touch "${HOME}/.bashrc_alias"
fi

if [ $(grep -ic "\$HOME/.bashrc_alias" "${HOME}/.bashrc" ) -lt 1  ]; then
  echo "" >> "${HOME}/.bashrc"
  cat >> $HOME/.bashrc << EOF
if [ -f "\$HOME/.bashrc_alias" ] ; then
   . "\$HOME/.bashrc_alias"
fi
EOF
fi

if [ $(grep -ic "alias aws=" "${HOME}/.bashrc_alias" ) -lt 1  ]; then
  # https://hub.docker.com/r/amazon/aws-cli
  echo "alias aws='docker run --rm -ti -v ~/.aws:/root/.aws -v $(pwd):/aws amazon/aws-cli:latest'" >> "${HOME}/.bashrc_alias"
fi

if [ $(grep -ic "alias az=" "${HOME}/.bashrc_alias" ) -lt 1  ]; then
  # https://hub.docker.com/_/microsoft-azure-cli
  echo "alias az='docker run --rm -ti -v ~/.azure:/root/.azure mcr.microsoft.com/azure-cli:latest'" >> "${HOME}/.bashrc_alias"
fi


popd

