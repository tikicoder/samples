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
root_path=$parent_path

while [ ! -f "${root_path}/_root" ]; 
do
    root_path=$(realpath "${root_path}/../")
done

source "${root_path}/common/general.sh"

tmp_invoke_file=$(mktemp)
echo "${default_bodyjson/\%refname\%/"$default_reporef"}" > $tmp_invoke_file

az devops invoke \
  --area pipelines --resource preview --api-version 7.1 --http-method post \
  --route-parameters pipelineId=${pipeline_id} project="${project}" --in-file $tmp_invoke_file \
  | jq -r ".finalYaml | length/1024/1024"

  rm $tmp_invoke_file