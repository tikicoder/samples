#!/bin/bash

# References to fix network
# https://docs.docker.com/network/bridge/
# https://docs.rockylinux.org/guides/network/basic_network_configuration/


docker_group_guid=$1

docker_host=$2
share_path=$3
docker_sock="${share_path}/$4"



# This updates the Docker ID to match the global id
if [ $(grep -ic "^docker:x" /etc/group) -lt 1 ]; then
  sudo addgroup --gid $docker_group_guid docker
else
  sudo groupmod -g $docker_group_guid docker
fi

# Updates the connected user
sudo usermod -aG docker `whoami`

if [ $(grep -ic "export DOCKER_SOCK=" $HOME/.bashrc) -lt 1 ]; then
  echo "" >> $HOME/.bashrc
  echo "# Docker Default Socket" >> $HOME/.bashrc
  echo "export DOCKER_SOCK=\"${docker_sock}\"" >> $HOME/.bashrc
fi

if [ $(grep -ic "export DOCKER_HOST=" $HOME/.bashrc) -lt 1 ]; then
  echo "" >> $HOME/.bashrc
  echo "# Docker Default Host" >> $HOME/.bashrc
  echo "export DOCKER_HOST=\"${docker_host}${docker_sock}\"" >> $HOME/.bashrc
fi

EOF
fi

