#!/bin/bash


DOCKER_DIR=$1
mkdir -pm o=,ug=rwx "$DOCKER_DIR"
chgrp docker "$DOCKER_DIR"

pushd /tmp
if [ $(sudo ls /etc | grep -ic "^docker$") -lt 1 ]; then
  sudo mkdir /etc/docker/
fi

echo "create/modify /etc/docker/daemon.json"
cat > ./daemon.json << EOF
{
  "hosts": ["$2", "$3"],
  "iptables": false
}
EOF
sudo mv ./daemon.json /etc/docker/daemon.json

echo "updating docker.service"
# This updates it to not use the normal launcher
sudo sed -i 's/ExecStart\=\/usr\/bin\/dockerd /# ExecStart\=\/usr\/bin\/dockerd/' /usr/lib/systemd/system/docker.service
sudo sed -i '/# ExecStart=\/usr\/bin\/dockerd/a ExecStart=\/usr\/bin\/dockerd' /usr/lib/systemd/system/docker.service



echo "reloading services"
sudo systemctl daemon-reload

echo "enabling and starting docker"
sudo systemctl enable docker
sudo systemctl start docker

popd