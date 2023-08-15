#!/bin/bash

general_container_guid=$1
sudo dnf install -y podman podman-compose podman-docker

systemctl --user start podman.socket
systemctl --user enable podman.socket
systemctl --user daemon-reload


sudo groupadd -g $general_container_guid grp_general_container

sudo usermod -a -G grp_general_container $(whoami)

mkdir -p "${HOME}/tmp/minikube_install"
cd "${HOME}/tmp/minikube_install"
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
sudo rpm -Uvh minikube-latest.x86_64.rpm

cd ../
rm -Rf "${HOME}/tmp/minikube_install"
