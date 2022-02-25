#!/bin/bash

DOCKER_DIR=/mnt/wsl/shared-docker
mkdir -pm o=,ug=rwx "$DOCKER_DIR"
chgrp docker "$DOCKER_DIR"

if [ $(sudo ls /etc | grep -ic "^docker$") -lt 1 ]; then
  sudo mkdir /etc/docker/
fi


cat | sudo tee /etc/docker/daemon.json <<EOF
{
  "hosts": ["unix:///mnt/wsl/shared-docker/docker.sock"],
  "iptables": false
}
EOF

# This updates it to not use the normal launcher
sudo sed -i 's/ExecStart\=\/usr\/bin\/dockerd /# ExecStart\=\/usr\/bin\/dockerd/' /usr/lib/systemd/system/docker.service
sudo sed -i '/# ExecStart=\/usr\/bin\/dockerd/a ExecStart=\/usr\/bin\/dockerd' /usr/lib/systemd/system/docker.service
sudo systemctl daemon-reload

sudo systemctl enable docker
sudo systemctl start docker
