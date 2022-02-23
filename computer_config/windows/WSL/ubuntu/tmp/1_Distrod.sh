#!/bin/bash

# Distrod - WSL2 Distros with Systemd!
# https://github.com/nullpo-head/wsl-distrod
curl -L "https://raw.githubusercontent.com/nullpo-head/wsl-distrod/main/install.sh"
chmod +x install.sh
sudo ./install.sh install

/opt/distrod/bin/distrod enable --start-on-windows-boot

mv distrod_update.sh ~/.local/bin/distrod_update.sh
chmod 755 ~/.local/bin/distrod_update.sh