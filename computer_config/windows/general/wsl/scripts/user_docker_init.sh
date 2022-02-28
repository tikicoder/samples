#!/bin/bash

DOCKER_SOCK="$1"
DOCKER_HOST="$2"
DOCKER_DISTRO="$3"
DOCKER_DIR="$4/shared-docker"

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
  echo "export DOCKER_DISTRO=\"${DOCKER_DIR}\"" >> $HOME/.bashrc
fi

if [ $(grep -ic "sudo systemctl start docker" $HOME/.bashrc) -lt 1 ]; then
  echo "" >> $HOME/.bashrc
  echo "# Auto Start Docker on distro start" >> $HOME/.bashrc
  cat >> $HOME/.bashrc << EOF
if [ ! -S "$DOCKER_SOCK" ]; then
  /mnt/c/Windows/System32/wsl.exe -d $DOCKER_DISTRO sudo systemctl start docker
fi
EOF
fi

