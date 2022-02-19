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


user_name=$(whoami)
user_home="${HOME}"
user_aliases="${user_home}/.bash_aliases"

mkdir -p "${HOME}/.local/bin"
PATH="$HOME/.local/bin:$PATH"



mkdir -p $tmp_directory
cd $tmp_directory


# nvm installer
wget -qO- https://raw.githubusercontent.com/nvm-sh/nvm/v0.39.1/install.sh | bash
source ~/.bashrc

#mikefarah yaml (JQ but for yaml)
wget https://github.com/mikefarah/yq/releases/download/${yq_version}/yq_linux_amd64 -q -O ~/.local/bin/yq
chmod +x ~/.local/bin/yq

# Enables Auto Upgrade w/Prompt
# https://docs.microsoft.com/en-us/cli/azure/update-azure-cli
az config set auto-upgrade.enable=yes

# Install extensions automatically w/Prompt
# https://docs.microsoft.com/en-us/cli/azure/azure-cli-extensions-overview
az config set extension.use_dynamic_install=yes_prompt

cd /tmp
rm -Rf $tmp_directory


if [ ! -f "$user_aliases" ]; then
  touch $user_aliases
fi