#!/bin/bash

last_key=""
while [ -n "$1" ]; do # while loop starts
    echo "$1"
    case "$1" in     
        --skip-prompt) skip_prompt=1
        ;;   
        --default) terraform_set_default=1
        ;;

        *)
            if [[ "${1}" =~ ^-- ]]; then
                last_key="$1"
                shift
                continue
            fi

            if [[ "${last_key}" =~ ^--save-path ]]; then
                terraform_savePath="$1"
                last_key=""
                shift
                continue
            fi

            if [[ "${last_key}" =~ ^--version ]] || [ -z "${last_key}" ]; then
                terraform_version="$1"
                last_key=""
                shift
                continue
            fi

	esac

	shift

done

function validate_flags(){

    if [ $skip_prompt -eq 1 ]; then
        return
    fi

    while [ -z "${terraform_savePath}" ]; do
        echo "The save path for downloading terraform is empty, please provide a path to save the file. (--save-path=)"
        read terraform_savePath
    done

}
