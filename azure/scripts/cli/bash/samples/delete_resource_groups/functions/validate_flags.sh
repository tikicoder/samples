#!/bin/bash

function validate_flags(){
    # work on system to allow spaces in key values
    while [ -n "$1" ]; do # while loop starts
        echo "working on $1"
        case "$1" in    
            --dry-run) dry_run=1
            ;;
            --apply) apply_delete=1
            ;;
            --tenant-id=*) tenant_id=$(echo $1  | awk -F= '{print $2}')
            ;;
            --subscription-exclude=*) subscription_exclude=$(echo $1  | awk -F= '{print $2}')
            ;;        
            --subscription-filter=*) subscription_filter=$(echo $1  | awk -F= '{print $2}')
            ;;
            --filter-rgnames=*) filter_resource_group_names=$(echo $1  | awk -F= '{print $2}')
            ;;
        esac

        shift

    done

}
