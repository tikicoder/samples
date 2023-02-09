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
source "${HOME}/.local/python/bin/activate" 

tmp_directory=$1

cat >> "${user_home}/.bashrc_wslg" << EOF
export LC_ALL=C
EOF

sudo chown $user_name:$user_name "${user_home}/.bashrc_wslg"
sudo chmod 644 "${user_home}/.bashrc_wslg"

popd

