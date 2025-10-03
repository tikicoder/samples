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
general_tmp_dir=$1
current_user=$(echo `whoami`)

cd ~
if [ -f "${general_tmp_dir}/disable_sudo_pass.sh" ]; then
    bash "$general_tmp_dir/disable_sudo_pass.sh" "$current_user"
fi






sudo apt list --upgradable
sudo apt update
sudo apt upgrade -y

sudo apt install -y ca-certificates dbus-user-session 
sudo apt install -y --fix-missing xfonts-base xfonts-100dpi xfonts-75dpi
sudo apt -y install "python$(python3 -c 'import sys; print(f"{sys.version_info[:][0]}.{sys.version_info[:][1]}")')-venv"

sudo apt install -y --fix-missing dos2unix

mkdir -p "${HOME}/.local/bin"
sudo chown -R $current_user:$current_user "${HOME}/.local"

# This is creating a local python environment I can use as the user
sudo python3 -m venv "${HOME}/.local/python"
sudo chown -R $current_user:$current_user "${HOME}/.local/python" 
source "${HOME}/.local/python/bin/activate" 

if [ ! -f "${HOME}/.local/python/pip.conf" ]; then
    echo "[install]" | sudo tee "${HOME}/.local/python/pip.conf"
    echo "user = false" | sudo tee -a "${HOME}/.local/python/pip.conf"
    echo "" | sudo tee -a  "${HOME}/.local/python/pip.conf"
fi

python3 -m pip install certifi

if [ -f "${general_tmp_dir}/disable_sudo_pass.sh" ]; then
    mv "$general_tmp_dir/disable_sudo_pass.sh" ~/.local/bin/disable_sudo_pass
    sudo chown ${current_user}:${current_user} ~/.local/bin/disable_sudo_pass
    sudo chmod 750 ~/.local/bin/disable_sudo_pass
fi

mv "$general_tmp_dir/download_release_github.sh" ~/.local/bin/download_release_github
sudo chown ${current_user}:${current_user} ~/.local/bin/download_release_github
sudo chmod 750 ~/.local/bin/download_release_github
