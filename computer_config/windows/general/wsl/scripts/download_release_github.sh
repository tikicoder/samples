#!/bin/bash

repo_owner=$1
repo=$2
file_name=$3
version="latest"
if [ $# -gt 3 ]; then
  version=$4
  version=$(echo "${version}" | tr '[:upper:]' '[:lower:]')
fi

mkdir -p /tmp/github-release/

if [ $version == "latest" ]; then
  version=$(curl -s https://api.github.com/repos/${repo_owner}/${repo}/releases/latest | jq -r '.tag_name')
fi

wget "https://github.com/${repo_owner}/${repo}/releases/download/${version}/${file_name}" -q -O /tmp/github-release/${file_name}
