#!/bin/bash

function validate_flags(){
   while [ -n "$1" ]; do # while loop starts
    echo "working on $1"
    case "$1" in    
        --dry-run) dry_run=1
        ;;
        --tenant-id=*) tenand_id=$(echo $1  | awk -F= '{print $2}')
        ;;
        --subscription-exclude=*) subscription_exclude=$(echo $1  | awk -F= '{print $2}')
        ;;        
        --subscription-filter=*) subscription_filter=$(echo $1  | awk -F= '{print $2}')
        ;;
	esac

	shift

done

}
