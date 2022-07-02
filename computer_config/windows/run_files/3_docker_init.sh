#!/bin/bash

if [ ! -f "${HOME}/.local" ]; then
  mkdir -p "${HOME}/.local/bin"
fi

if [ ! -f "${HOME}/.local/bin" ]; then
  mkdir -p "${HOME}/.local/bin"
fi

cp "${1}/3_docker_adduser.sh" "${HOME}/.local/bin"
chmod 755 "${HOME}/.local/bin/3_docker_adduser.sh"

sudo dnf check-update
sudo dnf update -y