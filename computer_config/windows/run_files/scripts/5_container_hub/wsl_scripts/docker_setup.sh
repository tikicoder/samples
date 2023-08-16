#!/bin/bash

# install Docker
# Thanks to the following articles
# https://www.tecmint.com/install-docker-in-rocky-linux-and-almalinux/
# https://docs.docker.com/engine/install/centos/``
# https://lippertmarkus.com/2021/09/04/containers-without-docker-desktop/
# https://dev.to/bowmanjd/install-docker-on-windows-wsl-without-docker-desktop-34m9

temp_folder=$1
host_tcp=$2 
docker_group=$3

username=$(whoami)
userid=$UID

mkdir -p $temp_folder/docker

# https://docs.docker.com/engine/reference/commandline/dockerd/
# https://gist.github.com/melozo/6de91558242fb8ca4212e4a73fbddde6
echo "create/modify /etc/docker/daemon.json"
cat > $temp_folder/docker/daemon.json << EOF
{
  "fixed-cidr": "192.168.32.0/19",
  "hosts": ["$DOCKER_HOST", "$host_tcp"],
  "iptables": false,
  "group"
}
EOF
sudo mv $temp_folder/docker/daemon.json /etc/docker/daemon.json

# dockerd-rootless-setuptool.sh install
# systemctl --user start docker
# systemctl --user enable docker
# sudo loginctl enable-linger $(whoami)