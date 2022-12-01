#!/bin/bash

# References to fix network
# https://docs.docker.com/network/bridge/
# https://docs.rockylinux.org/guides/network/basic_network_configuration/

DOCKER_SOCK="$1"
DOCKER_HOST="$2"
DOCKER_DISTRO="$3"
DOCKER_DIR="$4"

docker_groupid=$5

# This updates the Docker ID to match the global id
if [ $(grep -ic "^docker:x" /etc/group) -lt 1 ]; then
  sudo addgroup --gid $docker_groupid docker
else
  sudo groupmod -g $docker_groupid docker
fi




# Updates the connected user
sudo usermod -aG docker `whoami`

if [ $(grep -ic "export DOCKER_SOCK=" $HOME/.bashrc) -lt 1 ]; then
  echo "" >> $HOME/.bashrc
  echo "# Docker Default Socket" >> $HOME/.bashrc
  echo "export DOCKER_SOCK=\"${DOCKER_SOCK}\"" >> $HOME/.bashrc
fi

if [ $(grep -ic "export DOCKER_HOST=" $HOME/.bashrc) -lt 1 ]; then
  echo "" >> $HOME/.bashrc
  echo "# Docker Default Host" >> $HOME/.bashrc
  echo "export DOCKER_HOST=\"${DOCKER_HOST}\"" >> $HOME/.bashrc
fi

if [ $(grep -ic "export DOCKER_DISTRO=" $HOME/.bashrc) -lt 1 ]; then
  echo "" >> $HOME/.bashrc
  echo "# Docker WSL Distro" >> $HOME/.bashrc
  echo "export DOCKER_DISTRO=\"${DOCKER_DISTRO}\"" >> $HOME/.bashrc
fi

if [ $(grep -ic "export DOCKER_DIR=" $HOME/.bashrc) -lt 1 ]; then
  echo "" >> $HOME/.bashrc
  echo "# Docker WSL Share Folder" >> $HOME/.bashrc
  echo "export DOCKER_DIR=\"${DOCKER_DIR}\"" >> $HOME/.bashrc
fi

if [ $(grep -ic "sudo systemctl start docker" $HOME/.bashrc) -lt 1 ]; then
  echo "" >> $HOME/.bashrc
  echo "# Auto Start Docker on distro start" >> $HOME/.bashrc
  cat >> $HOME/.bashrc << EOF
if [ ! -d "\${DOCKER_DIR}" ]; then
  mkdir -p "\${DOCKER_DIR}"
  chgrp docker "\${DOCKER_DIR}"
fi

if [ ! -S "\$DOCKER_SOCK" ]; then
  /mnt/c/Windows/System32/wsl.exe -d "\$DOCKER_DISTRO" sudo systemctl start docker
fi
EOF
fi

