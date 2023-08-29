#!/bin/bash


mkdir -p "${HOME}/tmp/minikube_install"
cd "${HOME}/tmp/minikube_install"
curl -LO https://storage.googleapis.com/minikube/releases/latest/minikube-latest.x86_64.rpm
sudo rpm -Uvh minikube-latest.x86_64.rpm

cd ../
rm -Rf "${HOME}/tmp/minikube_install"
