#!/bin/bash

repo_owner=$1
repo=$2
file_name=$3
version="latest"
checksum_file=""
if [ $# -gt 3 ]; then
  version=$4
  version=$(echo "${version}" | tr '[:upper:]' '[:lower:]')
fi
if [ $# -gt 4 ]; then
  checksum_file=$5
fi

save_location="/tmp/github-release/${repo}"
mkdir -p $save_location

if [ $version == "latest" ]; then
  version=$(curl -s https://api.github.com/repos/${repo_owner}/${repo}/releases/latest | jq -r '.tag_name')
fi

wget https://github.com/${repo_owner}/${repo}/releases/download/${version}/${file_name} -q -O "${save_location}/${file_name}"

if [ ! -z "${checksum_file}" ]; then
  wget https://github.com/${repo_owner}/${repo}/releases/download/${version}/${checksum_file} -q -O "${save_location}/${checksum_file}"
fi