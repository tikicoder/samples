#!/bin/bash

user_name=$(whoami)
user_home="/home/${user_name}"

if [ -d "${user_home}/.local/bin/go" ]; then
    rm -Rf "${user_home}/.local/bin/go"
fi

mkdir -p /tmp/go
pushd /tmp/go
# Installing GOLANG to local BIN
wget https://go.dev/dl/go1.18.linux-amd64.tar.gz
tar -C "${user_home}/.local/bin" -xzf go1.18.linux-amd64.tar.gz
popd
rm -Rf /tmp/go
