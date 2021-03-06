#!/bin/bash

mkdir -p /tmp/distrod
pushd /tmp/distrod

# Distrod - WSL2 Distros with Systemd!
# https://github.com/nullpo-head/wsl-distrod
curl -L -O "https://raw.githubusercontent.com/nullpo-head/wsl-distrod/main/install.sh"
chmod +x install.sh
sudo ./install.sh update

popd
rm -Rf /tmp/distrod
