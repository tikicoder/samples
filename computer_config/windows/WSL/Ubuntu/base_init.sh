#!/bin/bash
set -e

cd ~
current_user=$(echo `whoami`)
sudo bash "$1/disable_sudo_pass.sh"

rm -Rf $1

sudo usermod -u $2 $current_user
sudo groupmod  -g $3 $current_user

mkdir -p $1

sudo apt list --upgradable
sudo apt update
sudo apt upgrade -y