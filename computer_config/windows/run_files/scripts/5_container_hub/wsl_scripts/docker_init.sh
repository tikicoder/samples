#!/bin/bash

# install Docker
# Thanks to the following articles
# https://www.tecmint.com/install-docker-in-rocky-linux-and-almalinux/
# https://docs.docker.com/engine/install/centos/``
# https://lippertmarkus.com/2021/09/04/containers-without-docker-desktop/
# https://dev.to/bowmanjd/install-docker-on-windows-wsl-without-docker-desktop-34m9

temp_folder=$1
docker_group=$2
docker_group_guid=$3


docker_host=$3
share_path=$4
docker_sock="${share_path}/$5"

username=$(whoami)
userid=$UID

sudo mkdir -p $share_path

sudo dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

sudo groupadd -g $docker_group_guid $docker_group
sudo usermod -a -G $docker_group $username

sudo chmod 755 $share_path
sudo chown $username:$docker_group $share_path

sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf update -y
sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-ce-rootless-extras
sudo dnf install -y dbus-user-session

docker --version

sudo sysctl net.ipv4.conf.all.forwarding=1
sudo iptables -A FORWARD -i eht0 -o docker0 -j ACCEPT
sudo iptables -A FORWARD -i eht0 -o docker0 -m state --state ESTABLISHED,RELATED -j ACCEPT
sudo iptables -t nat -A POSTROUTING -o eht0 -j MASQUERADE


echo "" >> "$HOME/.bashrc"

echo "# Docker Settings" >> "$HOME/.bashrc"
echo "export DOCKER_SOCK=\"$docker_sock\"" >> "$HOME/.bashrc"
echo "export DOCKER_HOST=\"${docker_host}${docker_sock}\"" >> "$HOME/.bashrc"

. "$HOME/.bashrc"


