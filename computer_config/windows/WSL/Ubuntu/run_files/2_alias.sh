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
  mkdir -p "${user_home}/.aws"
  # https://hub.docker.com/r/amazon/aws-cli

  ls -s "${user_home}/.docker_containers/aws/aws" "${user_home}/.aws"
  echo "alias aws='docker run --network host --rm -it -v ~/.aws:/root/.aws amazon/aws-cli'" >> "${user_home}/.bashrc_alias"
  echo "" >> "${user_home}/.bashrc_alias"
fi

if [ ! -f "${user_home}/.local/bin/az" ]; then
  mkdir -p "${user_home}/.azure"

  echo "alias az_update='docker pull mcr.microsoft.com/azure-cli && az config set extension.use_dynamic_install=yes_prompt'" >> "${user_home}/.bashrc_alias"

  cat >> "${user_home}/.local/bin/az" << EOF
args=""
while (( "$#" )); do
  args="${args} ${1}"
  shift
done

docker run --network host --rm -it -v ~/.ssh:/root/.ssh -v ~/.azure:/root/.azure tiki/azure_cli /usr/local/bin/az $args
EOF
chmod 755 "${user_home}/.local/bin/az"
fi

. "$user_home/.bashrc"
. "$user_home/.bashrc_alias"

az --version
aws --version

popd

