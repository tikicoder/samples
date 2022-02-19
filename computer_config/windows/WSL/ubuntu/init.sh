#!/bin/bash

user_name=$(whoami)
user_home="${HOME}"
user_aliases="${user_home}/.bash_aliases"

mkdir -p "${HOME}/.local/bin"
PATH="$HOME/.local/bin:$PATH"

yq_version="v4.16.2"
tmp_directory="/tmp/general_setup_config"
wsl_config_path="/etc/wsl.conf"

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

# nvm installer
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash

#mikefarah yaml (JQ but for yaml)
wget https://github.com/mikefarah/yq/releases/download/${yq_version}/yq_linux_amd64 -q -O ~/.local/bin/yq
chmod +x ~/.local/bin/yq

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
./aws/install



# Install Poetry
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -



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
rm -Rf /tmp/general_init


if [ ! -f "$user_aliases" ]; then
  touch $user_aliases
fi