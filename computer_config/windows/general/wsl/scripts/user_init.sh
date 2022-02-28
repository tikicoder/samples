#!/bin/bash

if [ $(grep -ic "nameserver 8.8.8.8" $HOME/.bashrc) -lt 1 ]; then
  if [ $(grep -ic "nameserver 8.8.8.8" /etc/resolv.conf) -lt 1 ]; then
    echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf
  fi
fi

