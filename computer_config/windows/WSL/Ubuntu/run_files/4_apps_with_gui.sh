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
source "${HOME}/.local/python/bin/activate" 

tmp_directory=$1

mkdir -p $tmp_directory
pushd $tmp_directory

sudo apt install -y gnome-text-editor
sudo apt install -y gedit gimp nautilus vlc x11-apps gtk2-engines-pixbuf

mkdir chrome
pushd chrome

# https://github.com/microsoft/wslg#install-and-run-gui-apps
sudo wget -O browser.deb https://dl.google.com/linux/direct/google-chrome-stable_current_amd64.deb
sudo apt install -f -y ./browser.deb


popd
rm -Rf chrome

mkdir edge
pushd edge

## Microsoft Edge Dev Browser
# sudo curl https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-dev/microsoft-edge-dev_101.0.1193.0-1_amd64.deb -o /tmp/edge.deb
# sudo apt install /tmp/edge.deb -y

## Microsoft Edge Stable Browser
sudo wget -O browser.deb https://packages.microsoft.com/repos/edge/pool/main/m/microsoft-edge-stable/microsoft-edge-stable_141.0.3537.57-1_amd64.deb?brand=M102
sudo apt install -f -y ./browser.deb


popd
rm -Rf edge


popd

echo "k8s lens"
# K8s Lens
# k8s_lens_version="2022.12.121519-latest"
# mkdir /tmp/k8s_lens
# pushd /tmp/k8s_lens
# wget "https://downloads.k8slens.dev/ide/Lens-${k8s_lens_version}.amd64.deb" -O k8s.lens.amd64.deb
# sudo apt install -y ./k8s.lens.amd64.deb
# popd
# rm -Rf /tmp/k8s_lens
curl -fsSL https://downloads.k8slens.dev/keys/gpg | gpg --dearmor | sudo tee /usr/share/keyrings/lens-archive-keyring.gpg > /dev/null
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/lens-archive-keyring.gpg] https://downloads.k8slens.dev/apt/debian stable main" | sudo tee /etc/apt/sources.list.d/lens.list > /dev/null
sudo apt update
sudo apt install lens

echo "freelens"
# Freelens is a free and open-source user interface designed for managing Kubernetes clusters
# https://github.com/freelensapp/freelens
freelens_version="latest"
freelens_version=$(echo "${freelens_version}" | tr '[:upper:]' '[:lower:]')
freelens_binary="Freelens-1.6.1-linux-amd64.deb"
download_release_github "freelensapp" "freelens" "${freelens_binary}" "${freelens_version}"
sudo apt install -f /tmp/github-release/freelens/Freelens-1.6.1-linux-amd64.deb
