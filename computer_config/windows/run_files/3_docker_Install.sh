#!/bin/bash

# install Docker
# Thanks to the following articles
# https://www.tecmint.com/install-docker-in-rocky-linux-and-almalinux/
# https://docs.docker.com/engine/install/centos/
# https://lippertmarkus.com/2021/09/04/containers-without-docker-desktop/
# https://dev.to/bowmanjd/install-docker-on-windows-wsl-without-docker-desktop-34m9

sudo dnf remove docker docker-client docker-client-latest docker-common docker-latest docker-latest-logrotate docker-logrotate docker-engine

sudo dnf config-manager --add-repo=https://download.docker.com/linux/centos/docker-ce.repo
sudo dnf update -y
sudo dnf install -y docker-ce docker-ce-cli containerd.io

docker --version

echo "Adding user to add to docker group: $1"
sudo usermod -aG docker $1

echo "" >> "$HOME/.bashrc"

echo "# Docker Settings" >> "$HOME/.bashrc"
echo "export DOCKER_SOCK=\"$2\"" >> "$HOME/.bashrc"
echo "export DOCKER_HOST=\"$3\"" >> "$HOME/.bashrc"

. "$HOME/.bashrc"


