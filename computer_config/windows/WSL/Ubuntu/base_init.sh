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

base_dir="$(dirname $(realpath $0))"

cd ~
current_user=$(echo `whoami`)
bash "$base_dir/disable_sudo_pass.sh" "$current_user"


sudo apt list --upgradable
sudo apt update
sudo apt upgrade -y

sudo apt install -y ca-certificates

# This is creating a local python environment I can use as the user
sudo python3 -m venv "${HOME}/.local/python"
sudo chown -R $current_user:$current_user "${HOME}/.local/python" 
source "${HOME}/.local/python/bin/activate" 

if [ ! -f "${HOME}/.local/python/pip.conf" ]; then
    echo "[install]" | sudo tee "${HOME}/.local/python/pip.conf"
    echo "user = false" | sudo tee -a "${HOME}/.local/python/pip.conf"
    echo "" | sudo tee -a  "${HOME}/.local/python/pip.conf"
fi

# install some common modules for python that is needed for some scripts to work
python3 -m pip install python-dateutil polling asyncio pycryptodomex boto3 botocore