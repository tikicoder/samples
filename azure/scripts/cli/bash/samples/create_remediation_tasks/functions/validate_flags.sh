#!/bin/bash

function validate_flags(){
    # work on system to allow spaces in key values
    while [ -n "$1" ]; do # while loop starts
        echo "working on $1"
        case "$1" in    
            --dry-run) dry_run=1
            ;;
            --tenant-id=*) tenant_id=$(echo $1  | awk -F= '{print $2}')
            ;;
            --subscription-exclude=*) subscription_exclude=$(echo $1  | awk -F= '{print $2}')
            ;;        
            --subscription-filter=*) subscription_filter=$(echo $1  | awk -F= '{print $2}')
            ;;
            --task-filter=*) create_remedation_tasks=$(echo $1  | awk -F= '{print $2}')
            ;;
            --task-filterodata=*) create_remedation_tasks_odata=$(echo $1  | awk -F= '{print $2}')
            ;;
            --delete-tasks) delete_existing_remediation_tasks=1
            ;;
            --mg-ids=*) management_groups=$(echo $1  | awk -F= '{print $2}')
            ;;
        esac

        shift

    done

}
