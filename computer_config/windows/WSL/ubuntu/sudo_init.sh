#!/bin/bash
set -e

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

source "${dir_path}/defaults.sh"

mkdir -p $tmp_directory
cd $tmp_directory

echo "$tmp_directory/missing_root_certs/*.crt"
cp $tmp_directory/missing_root_certs/*.crt /usr/local/share/ca-certificates/

update-ca-certificates --fresh

apt update
apt upgrade -y


# WSL COnfiguration update
if [ ! -f "$wsl_config_path" ]; then
  touch $wsl_config_path
fi

if [ $(grep -ic "\[automount\]" $wsl_config_path) -lt 1  ]; then
  echo "[automount]" >> $wsl_config_path
  echo "enabled = true" >> $wsl_config_path
  echo 'options = "metadata,umask=22,fmask=11"' >> $wsl_config_path
fi


# general prerequest
apt install software-properties-common

# general prerequest - Python
if [ $(grep -irc "deadsnakes/ppa" /etc/apt/sources.list.d/ | awk -F: '{print $2 }' | awk '{ sum += $1 } END { print sum }') -lt 1  ]; then
  add-apt-repository ppa:deadsnakes/ppa -y
fi


# Python 3.9
apt install -y python3.9


# JQ
apt install -y jq

# GitHub CLI
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
apt update
apt install -y gh

# Azure CLI
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash

#AWS CLI
curl "https://awscli.amazonaws.com/awscli-exe-linux-$(uname -m).zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install


# Install steampipe
sudo /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/turbot/steampipe/main/install.sh)"
steampipe plugin install steampipe


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

cd /tmp
rm -Rf $tmp_directory
