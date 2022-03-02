#!/bin/bash

disable_sudo_user=$(echo `whoami`)
if [ $# -gt 0 ]; then
  if [ ! -z "$1" ]; then
    disable_sudo_user=$1
  fi
fi
echo "$disable_sudo_user ALL=(ALL) NOPASSWD:ALL" | sudo tee "/etc/sudoers.d/$disable_sudo_user"
sudo chmod 0440 "/etc/sudoers.d/$disable_sudo_user"
