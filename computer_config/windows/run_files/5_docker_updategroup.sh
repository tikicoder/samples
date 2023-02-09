#!/bin/bash

if [ -z "$(command -v groupmod)" ]; then
  sudo sed -i -e 's/^\(docker:x\):[^:]\+/\1:36257/' /etc/group
  exit
fi

sudo groupmod -g 36257 docker



