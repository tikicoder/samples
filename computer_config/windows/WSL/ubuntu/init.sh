#!/bin/bash

user_name=$(whoami)
user_home="${HOME}"
mkdir -p "${HOME}/.local/bin"
PATH="$HOME/.local/bin:$PATH"

yq_version="v4.16.2"
tmp_directory="/tmp/general_setup_config"

mkdir -p $tmp_directory
cd $tmp_directory

echo "$tmp_directory/missing_root_certs/*.crt"
cp $tmp_directory/missing_root_certs/*.crt /usr/local/share/ca-certificates/

update-ca-certificates --fresh

apt update
apt upgrade -y


# WSL COnfiguration update
echo "" >> /etc/wsl.conf
echo "[automount]" >> /etc/wsl.conf
echo "enabled = true" >> /etc/wsl.conf
echo 'options = "metadata,umask=22,fmask=11"' >> /etc/wsl.conf

# general prerequest
apt-get install software-properties-common

# general prerequest - Python
add-apt-repository ppa:deadsnakes/ppa


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



# Install Poetryr
curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -


cd /tmp
rm -Rf /tmp/general_init



echo "" >> "${user_home}/.bash_aliases"