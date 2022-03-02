#!/bin/bash
set -e

cd ~
current_user=$(echo `whoami`)
sudo bash "$1/disable_sudo_pass.sh"


sudo apt list --upgradable
sudo apt update
sudo apt upgrade -y