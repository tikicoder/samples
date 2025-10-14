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
source "${HOME}/.local/python/bin/activate" 

tmp_directory=$1
docker_groupid=$

mkdir -p $tmp_directory
pushd $tmp_directory

if [ ! -f "${user_aliases}" ]; then
  touch "${user_aliases}"
fi

if [ $(grep -ic "bashrc_extra_FILES=" "${user_home}/.bashrc" ) -lt 1  ]; then
  echo "" >> "${user_home}/.bashrc"
  cat >> "${user_home}/.bashrc" << EOF
bashrc_extra_FILES="\${HOME}/.bashrc_*";
for bashrc_extra in \$bashrc_extra_FILES; do
   . "\$bashrc_extra"
done;
EOF
fi

if [ ! $(command -v "gh") ]; then
  if [ $(grep -ic "alias ghauthtiki='gh auth switch -u tikicoder;gh auth setup-git'" "${user_aliases}" ) -lt 1  ]; then
    echo "alias ghauthtiki='gh auth switch -u tikicoder;gh auth setup-git" >> "${user_aliases}"
  fi
  if [ $(grep -ic "alias ghtiki='gh auth switch -u tikicoder;gh auth setup-git;gh'" "${user_aliases}" ) -lt 1  ]; then
    echo "alias ghtiki='gh auth switch -u tikicoder;gh auth setup-git;gh'" >> "${user_aliases}"
  fi
  if [ $(grep -ic "alias gittiki='gh auth switch -u tikicoder;gh auth setup-git;git'" "${user_aliases}" ) -lt 1  ]; then
    echo "alias gittiki='gh auth switch -u tikicoder;gh auth setup-git;git'" >> "${user_aliases}"
  fi
fi



if [ ! $(command -v "kubectl") ]; then
  if [ $(grep -ic "alias k=kubectl" "${user_aliases}" ) -lt 1  ]; then
    echo "alias k=kubectl" >> "${user_aliases}"
  fi
fi
if [ ! $(command -v "microsoft-edge") ]; then
  if [ $(grep -ic "ie-edge=" "${user_aliases}" ) -lt 1  ]; then
    echo "alias ie-edge='2>/dev/null 1>&2 microsoft-edge --enable-unsafe-swiftshader &'" >> "${user_aliases}"
  fi
fi
if [ ! $(command -v "google-chrome") ]; then
  if [ $(grep -ic "chrome-google=" "${user_aliases}" ) -lt 1  ]; then
    echo "alias chrome-google='2>/dev/null 1>&2 google-chrome --disable-gpu &'" >> "${user_aliases}"
  fi
fi
echo "" >> "${user_aliases}"

# move to script so can check if any exists
# if [ $(grep -ic "alias dockimage-clear=docker image ls -a | grep -iv \"IMAGE\" | awk -F" " '{print \$3}'" "${user_aliases}" ) -lt 1  ]; then

#   echo "alias dockimage-clear=docker image ls -a | grep -iv \"IMAGE\" | awk -F" " '{print \$3}' | xargs docker image rm" >> "${user_aliases}"
#   echo "" >> "${user_aliases}"
# fi

# if [ $(grep -ic "alias dockcontainer-clear=docker container ls -a | grep -iv \"IMAGE\" | awk -F" " '{print \$1}'" "${user_aliases}" ) -lt 1  ]; then

#   echo "alias dockcontainer-clear=docker container ls -a | grep -iv \"IMAGE\" | awk -F" " '{print \$1}' | xargs docker container rm" >> "${user_aliases}"
#   echo "" >> "${user_aliases}"
# fi

# https://docs.docker.com/network/bridge/#differences-between-user-defined-bridges-and-the-default-bridge
# using --network host while work to figure the bridge config out

# if [ $(grep -ic "alias aws=" "${user_aliases}" ) -lt 1  ]; then
#   mkdir -p "${user_home}/.aws"
#   # https://hub.docker.com/r/amazon/aws-cli

#   echo "# alias aws='docker run --network host --rm -it -v ~/.aws:/root/.aws amazon/aws-cli'" >> "${user_aliases}"
#   echo "" >> "${user_aliases}"
# fi

# if [ ! -f "${user_home}/.local/bin/az" ]; then
#   mkdir -p "${user_home}/.azure"

#   echo "# alias az_update='docker pull mcr.microsoft.com/azure-cli && az config set extension.use_dynamic_install=yes_prompt'" >> "${user_aliases}"
#   echo "# alias az='docker run --network host --rm -it -v ~/.ssh:/root/.ssh -v ~/.azure:/root/.azure tiki/azure_cli /usr/local/bin/az'" >> "${user_aliases}"

# # If you would rather a script file to load az

# #   cat >> "${user_home}/.local/bin/az" << EOF
# # args=""
# # while (( "$#" )); do
# #   args="${args} ${1}"
# #   shift
# # done

# # docker run --network host --rm -it -v ~/.ssh:/root/.ssh -v ~/.azure:/root/.azure tiki/azure_cli /usr/local/bin/az $args
# # EOF
# # chmod 755 "${user_home}/.local/bin/az"
# fi

# if [ $(grep -ic "alias pwsh=" "${user_aliases}" ) -lt 1  ]; then
#   mkdir -p "${user_home}/.aws"
#   # https://hub.docker.com/_/microsoft-powershell

#   echo "alias pwsh='docker run --network host --rm -it -v ~/*:/root/ -v ~/mnt/c:/mnt/c  mcr.microsoft.com/powershell'" >> "${user_aliases}"
#   echo "" >> "${user_aliases}"
# fi

. "$user_home/.bashrc"
. "$user_home/.bashrc_alias"

az --version
aws --version


popd

