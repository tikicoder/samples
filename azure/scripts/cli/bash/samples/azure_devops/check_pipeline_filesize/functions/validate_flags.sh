#!/bin/bash

function validate_flags(){
    # work on system to allow spaces in key values
    while [ -n "$1" ]; do # while loop starts
        echo "working on $1"
        case "$1" in    
            --dry-run) dry_run=1
            ;;
            --project=*) project=$(echo $1  | awk -F= '{print $2}')
            ;;
            --pipeline=*) pipeline_id=$(echo $1  | awk -F= '{print $2}')
            ;;
            --repo-ref=*) default_reporef=$(echo $1  | awk -F= '{print $2}')
            ;;
        esac

        shift

    done

}
