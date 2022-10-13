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

base_init

echo ""

source "${dir_path}/tasks/subscription.sh"

echo ""

