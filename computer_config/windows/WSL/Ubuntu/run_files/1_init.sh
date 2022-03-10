#!/bin/bash

if [ ! $(command -v "realpath") ]; then
    realpath() {
    OURPWD=$PWD
    cd "$(dirname "$1")"
    LINK=$(readlink "$(basename "$1")")
    while [ "$LINK" ]; do
        cd "$(dirname "$LINK")"
        LINK=$(readlink "$(basename "$1")")
    done
    REALPATH="$PWD/$(basename "$1")"
    cd "$OURPWD"
    echo "$REALPATH"
    }
fi

full_path=$(realpath $0)
dir_path=$(dirname $full_path)
parent_path=$(realpath "${dir_path}/../")

user_name=$(whoami)
user_home="/home/${user_name}"
user_aliases="${user_home}/.bashrc_alias"

mkdir -p "${user_home}/.local/bin"

tmp_directory=$1

mkdir -p $tmp_directory
pushd $tmp_directory


sudo apt update
sudo apt upgrade -y

if [ $(sudo ls /etc/ | grep -ic '^wsl.conf$') -gt 0  ]; then
  sudo rm -f /etc/wsl.conf
fi
sudo cp  ./wsl.conf /etc/wsl.conf

# Goal run as much as I can via Docker
# https://blog.jessfraz.com/post/docker-containers-on-the-desktop/

# general prerequest
# apt install software-properties-common

# not installing 3.9 as that is what I want to use poetry for
# general prerequest - Python
# if [ $(grep -irc "deadsnakes/ppa" /etc/apt/sources.list.d/ | awk -F: '{print $2 }' | awk '{ sum += $1 } END { print sum }') -lt 1  ]; then
#   add-apt-repository ppa:deadsnakes/ppa -y
# fi

# Python 3.9
# apt install -y python3.9

# Install genisoimage helpful for converting AWS Linux 2 to Azure
sudo apt install -y genisoimage

# Docker Requirments
# https://docs.docker.com/engine/install/ubuntu/
# https://dev.to/bowmanjd/install-docker-on-windows-wsl-without-docker-desktop-34m9
sudo apt-get -y install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# Docker GPG
source /etc/os-release
curl -fsSL https://download.docker.com/linux/${ID}/gpg | sudo apt-key add -

# Docker repo
echo "deb [arch=amd64] https://download.docker.com/linux/${ID} ${VERSION_CODENAME} stable" | sudo tee /etc/apt/sources.list.d/docker.list
sudo apt update


# Docker CLI
sudo apt-get update
sudo apt-get install -y docker-ce-cli

# kubectl key and repo
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -
echo "deb https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list

# JQ
# https://hub.docker.com/r/stedolan/jq
sudo apt install -y jq

# mikefarah yaml (JQ but for yaml)
# https://github.com/mikefarah/yq
wget https://github.com/mikefarah/yq/releases/download/${yq_version}/yq_linux_amd64 -q -O ~/.local/bin/yq
chmod +x ~/.local/bin/yq

# NVM
# https://github.com/nvm-sh/nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

# GitHub CLI
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update -y
sudo apt install -y gh

# Git Install
sudo apt install -y git

# # Azure CLI
# # https://docs.microsoft.com/en-us/cli/azure/run-azure-cli-docker
# # https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
# curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# # Enables Auto Upgrade w/Prompt
# # https://docs.microsoft.com/en-us/cli/azure/update-azure-cli
# az config set auto-upgrade.enable=yes

# # Install extensions automatically w/Prompt
# # https://docs.microsoft.com/en-us/cli/azure/azure-cli-extensions-overview
# az config set extension.use_dynamic_install=yes_prompt

# # AWS CLI
# # https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# # https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-docker.html
# curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
# unzip awscliv2.zip
# sudo ./aws/install

# # GCP CLI
# # https://cloud.google.com/sdk/docs/downloads-docker
# # https://cloud.google.com/sdk/docs/install#linux
# # curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-373.0.0-linux-x86_64.tar.gz
# # tar -xf google-cloud-sdk-373.0.0-linux-x86.tar.gz
# # ./google-cloud-sdk/install.sh


# Install steampipe
# https://steampipe.io/downloads
sudo /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/turbot/steampipe/main/install.sh)"
steampipe plugin install steampipe

# Install Poetry
# https://python-poetry.org/docs/master/#installing-with-the-official-installer
curl -sSL https://install.python-poetry.org | python3 -

# Install dotNet
wget https://packages.microsoft.com/config/ubuntu/21.04/packages-microsoft-prod.deb -O packages-microsoft-prod.deb
sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb

# Install dotNet SDK 6
sudo apt-get update; \
  sudo apt-get install -y apt-transport-https && \
  sudo apt-get update && \
  sudo apt-get install -y dotnet-sdk-6.0

# Install dotNet SDK 5
sudo apt-get install -y dotnet-sdk-5.0

# Installing ClojureCLR as a dotnet tool
dotnet tool install --global Clojure.Main

popd

