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
user_bash_file="${user_home}/.bashrc"
user_aliases="${user_home}/.bashrc_alias"

mkdir -p "${user_home}/.local/bin"
source "${HOME}/.local/python/bin/activate" 

tmp_directory=$1
apt_keyrings="/usr/local/share/keyrings/"

mkdir -p $tmp_directory
pushd $tmp_directory
sudo mkdir -p "$apt_keyrings"

sudo apt update
sudo apt upgrade -y

touch "${HOME}/.gtk-bookmarks"
chmod $user_name:$user_name "${HOME}/.gtk-bookmarks"
chmod 644 "${HOME}/.gtk-bookmarks"
# Base Packages Install
sudo apt install -y make bash-completion git pylint

echo "Installing GOLANG"
mkdir -p /tmp/go
pushd /tmp/go
# verify latest https://go.dev/dl/
# Installing GOLANG to local BIN
wget -O go1.linux-amd64.tar.gz  https://go.dev/dl/go1.20.linux-amd64.tar.gz
tar -C "${user_home}/.local/bin" -xzf go1.18.linux-amd64.tar.gz
popd
rm -Rf /tmp/go

if [ $(grep -ic "\"\$HOME/.local/bin\"" "${user_home}/.profile") -lt 1 ]; then
  cat >> "${user_home}/.profile" << EOF
# set PATH so it includes user's private bin if it exists
if [ -d "\$HOME/.local/bin" ]; then
    PATH="\$HOME/.local/bin:\$PATH"
fi
EOF
fi

if [ $(grep -ic "\"\$HOME/.local/bin/go/bin\"" "${user_home}/.profile") -lt 1 ]; then
  cat >> "${user_home}/.profile" << EOF
# set PATH so it includes user's private golang bin if it exists
if [ -d "\$HOME/.local/bin/go/bin" ]; then
    PATH="\$HOME/.local/bin/go/bin:\$PATH"
fi
EOF
fi

echo "Ensuring base WSL.conf"
if [ $(sudo ls /etc/ | grep -ic '^wsl.conf$') -gt 0  ]; then
  sudo rm -f /etc/wsl.conf
fi
sudo cp  ./wsl.conf /etc/wsl.conf

# This will allow the docker host to see files here
sudo sh -c "echo \"/ /mnt/wsl/instances/Ubuntu none defaults,bind,X-mount.mkdir 0 0\" >> /etc/fstab"
sudo mount -a

echo "install normal zip/unzip"
# adding the ability to zip/unzip
sudo apt-get install -y zip unzip

echo "Insall MS packages"
declare repo_version=$(if command -v lsb_release &> /dev/null; then lsb_release -r -s; else grep -oP '(?<=^VERSION_ID=).+' /etc/os-release | tr -d '"'; fi)
wget https://packages.microsoft.com/config/ubuntu/$repo_version/packages-microsoft-prod.deb -O packages-microsoft-prod.deb

sudo dpkg -i packages-microsoft-prod.deb
rm packages-microsoft-prod.deb
sudo apt-get update

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

echo "install genisoimage"
# Install genisoimage helpful for converting AWS Linux 2 to Azure
sudo apt install -y genisoimage

echo "install graphviz"
# GraphViz this is a useful tool for graphing and is used for Diagramming as Code.
# https://graphviz.gitlab.io/download/
sudo apt install -y graphviz

echo "install powershell"
sudo apt-get install -y powershell

# This is designed to have Node use the Same CA as python so if something custom is there you should be good
if [ $(grep -ic "export NODE_EXTRA_CA_CERTS=" "${user_bash_file}" ) -lt 1  ]; then
  echo "" >> "${user_bash_file}"
  echo "export NODE_EXTRA_CA_CERTS='$(python3 -m certifi)'" >> "${user_bash_file}"
  echo "" >> "${user_bash_file}"
fi

# This is designed to have Node use the Same CA as python so if something custom is there you should be good
if [ $(grep -ic "source "\${HOME}/.local/python"" "${user_bash_file}" ) -lt 1  ]; then
  echo "" >> "${user_bash_file}"
  echo "# this is to use my venv for python" >> "${user_bash_file}"
  echo "source \"\${HOME}/.local/python/bin/activate\""  >> "${user_bash_file}"
  echo "" >> "${user_bash_file}"
fi

echo "Docker Setup"
# Docker Requirments
# https://docs.docker.com/engine/install/ubuntu/
# https://dev.to/bowmanjd/install-docker-on-windows-wsl-without-docker-desktop-34m9
sudo apt-get -y install \
  ca-certificates \
  curl \
  gnupg \
  lsb-release

# Docker GPG / Docker repo
source /etc/os-release
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --yes --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null



# Docker CLI
sudo apt-get update
sudo apt-get install -y docker-ce-cli

echo "JQ"
# JQ
# https://hub.docker.com/r/stedolan/jq
sudo apt install -y jq

echo "yamllint"
# yamllint
# https://github.com/adrienverge/yamllint
sudo apt-get install -y yamllint

echo "yq"
# mikefarah yaml (JQ but for yaml)
# https://github.com/mikefarah/yq
yq_version="latest"
yq_version=$(echo "${yq_version}" | tr '[:upper:]' '[:lower:]')
download_release_github "derailed" "k9s" "k9s_Linux_amd64.tar.gz" "${yq_version}"
# if [ $yq_version == "latest" ]; then
#   yq_version=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest | jq -r '.tag_name')
# fi

# if [ -f "${user_home}/.local/bin/yq" ]; then
#   rm -f "${user_home}/.local/bin/yq"
# fi
# wget https://github.com/mikefarah/yq/releases/download/${yq_version}/yq_linux_amd64 -q -O ~/.local/bin/yq

mv /tmp/github-release/yq_linux_amd64 ~/.local/bin/yq
chmod +x ~/.local/bin/yq
sudo rm /tmp/github-release/yq_linux_amd64

echo "7zip"
# https://www.7-zip.org/download.html
sevenZip_version="2301-linux-x64"
sevenZip_version_url="https://www.7-zip.org/a/7z${sevenZip_version}.tar.xz"
mkdir -p /tmp/7zip/contents
wget $sevenZip_version_url -q -O /tmp/7zip/7zip.tar.xz
pushd /tmp/7zip/contents

tar -xvzf ../7zip.tar.xz ./

popd

echo "NVM"
# NVM
# https://github.com/nvm-sh/nvm
nvm_version="latest"
nvm_version=$(echo "${nvm_version}" | tr '[:upper:]' '[:lower:]')
if [ $nvm_version == "latest" ]; then
  nvm_version=$(curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | jq -r '.tag_name')
fi

curl -o- "https://raw.githubusercontent.com/nvm-sh/nvm/${nvm_version}/install.sh" | bash

echo "gh cli"
# GitHub CLI
# https://github.com/cli/cli/blob/trunk/docs/install_linux.md
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update -y
sudo apt install -y gh

echo "az cli"
# Azure CLI
# https://docs.microsoft.com/en-us/cli/azure/run-azure-cli-docker
# https://docs.microsoft.com/en-us/cli/azure/install-azure-cli-linux?pivots=apt
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash
# Enables Auto Upgrade w/Prompt
# https://docs.microsoft.com/en-us/cli/azure/update-azure-cli
az config set auto-upgrade.enable=yes

# Install extensions automatically w/Prompt
# https://docs.microsoft.com/en-us/cli/azure/azure-cli-extensions-overview
az config set extension.use_dynamic_install=yes_prompt

# this will install and upgradeaz bicep
az bicep upgrade

# Without Prompt
# az config set extension.use_dynamic_install=yes_without_prompt

echo "Azure Powershell"
pwsh -Command Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

pwsh -Command Install-Module -Name PSRule -Scope CurrentUser -Repository PSGallery -Force
pwsh -Command "Find-Module -Repository PSGallery -Name 'PSRule.Rules.*' | ForEach-Object{ Install-Module -Name \$_.Name -Scope CurrentUser -Repository PSGallery -Force}"

echo "aws cli"
# AWS CLI
# https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html
# https://docs.aws.amazon.com/cli/latest/userguide/install-cliv2-docker.html
mkdir -p /tmp/aws
pushd /tmp/aws
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
popd
rm -Rf /tmp/aws

echo "kubectl"
# kubectl install - Manually
# mkdir -p /tmp/kube
# pushd /tmp/kube
# curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
# chmod 755 kubectl
# mv ./kubectl ~/.local/bin/kubectl
# popd
# rm -Rf /tmp/kube

# kubectl install - pkg manager
sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubectl

# This is designed to have Node use the Same CA as python so if something custom is there you should be good
if [ $(grep -ic "source <(kubectl completion bash)" "${user_bash_file}" ) -lt 1  ]; then
  echo "" >> "${user_bash_file}"
  echo "source <(kubectl completion bash)" >> "${user_bash_file}"
  echo "complete -o default -F __start_kubectl k" >> "${user_bash_file}"
  echo "" >> "${user_bash_file}"
fi

# kubectl convert install - Manually
mkdir -p /tmp/kube
pushd /tmp/kube
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl-convert"
chmod 755 kubectl-convert
mv ./kubectl-convert ~/.local/bin/kubectl-convert
popd
rm -Rf /tmp/kube

# krew for kubectl - Plugins Manager
# https://krew.sigs.k8s.io/docs/user-guide/setup/install/
(
  set -x; cd "$(mktemp -d)" &&
  OS="$(uname | tr '[:upper:]' '[:lower:]')" &&
  ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')" &&
  KREW="krew-${OS}_${ARCH}" &&
  curl -fsSLO "https://github.com/kubernetes-sigs/krew/releases/latest/download/${KREW}.tar.gz" &&
  tar zxvf "${KREW}.tar.gz" &&
  ./"${KREW}" install krew
)

echo 'export PATH="${KREW_ROOT:-$HOME/.krew}/bin:$PATH"' >> "${user_bash_file}"
echo "" >> "${user_bash_file}"


# attempting to refresh bash after krew install
exec bash

# kubectx + kubens: Power tools for kubectl
# https://github.com/ahmetb/kubectx
kubectl krew install ctx
kubectl krew install ns

# # GCP CLI
# # https://cloud.google.com/sdk/docs/downloads-docker
# # https://cloud.google.com/sdk/docs/install#linux
# # curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-sdk-373.0.0-linux-x86_64.tar.gz
# # tar -xf google-cloud-sdk-373.0.0-linux-x86.tar.gz
# # ./google-cloud-sdk/install.sh

echo "steampipe"
# Install steampipe
# https://steampipe.io/downloads
sudo /bin/sh -c "$(curl -fsSL https://raw.githubusercontent.com/turbot/steampipe/main/install.sh)"
steampipe plugin install steampipe

echo "poetry"
# Install Poetry
# https://python-poetry.org/docs/master/#installing-with-the-official-installer
curl -sSL https://install.python-poetry.org | python3 -

echo "dotnet"
# Make sure things are removed
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-package-mixup?pivots=os-linux-ubuntu#i-need-a-version-of-net-that-isnt-provided-by-my-linux-distribution

sudo apt remove 'dotnet*' 'aspnet*' 'netstandard*'
if [ ! -f "/etc/apt/preferences.d/dotnet" ]; then
  sudo touch /etc/apt/preferences.d/dotnet
fi

sudo tee /etc/apt/preferences.d/dotnet << EOF
Package: dotnet* aspnet* netstandard*
Pin: origin "archive.ubuntu.com"
Pin-Priority: -10
EOF

# Install dotNet
# https://learn.microsoft.com/en-us/dotnet/core/install/linux-ubuntu

sudo apt-get update;
echo "dotNet LTS (currently .NET 6)"
# Install dotNet LTS
 
  sudo apt-get install -y apt-transport-https && \
  sudo apt-get install -y dotnet-sdk-6.0

echo "dotNet 7"
# Install dotNet SDK 7
sudo apt-get install -y dotnet-sdk-7.0
sudo apt-get install -y aspnetcore-runtime-7.0 dotnet-runtime-7.0

# Installing ClojureCLR as a dotnet tool
dotnet tool install --global Clojure.Main

popd

