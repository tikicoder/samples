#!/bin/bash

mkdir -p /tmp/distrod
# Distrod - WSL2 Distros with Systemd!
# https://github.com/nullpo-head/wsl-distrod
pushd /tmp/distrod

curl -L -O "https://raw.githubusercontent.com/nullpo-head/wsl-distrod/main/install.sh"
chmod +x install.sh
sudo ./install.sh install


popd

sudo mv "$1/3_docker_Distrod_update.sh" /usr/bin/distrod_update.sh
sudo chmod 755 /usr/bin/distrod_update.sh
sudo chown root:root /usr/bin/distrod_update.sh

rm -Rf /tmp/distrod