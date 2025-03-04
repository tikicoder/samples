#!/bin/bash

function validate_flags(){
   while [ -n "$1" ]; do # while loop starts
    echo "working on $1"
    case "$1" in
        --tenant-id=*) tenand_id=$(echo $1  | awk -F= '{print $2}')
        ;;
        --subscription-exclude=*) subscription_exclude=$(echo $1  | awk -F= '{print $2}')
        ;;        
        --subscription-filter=*) subscription_filter=$(echo $1  | awk -F= '{print $2}')
        ;;
        --blueprint-exclude=*) blueprint_exclude=$(echo $1  | awk -F= '{print $2}')
        ;;        
        --blueprint-filter=*) blueprint_filter=$(echo $1  | awk -F= '{print $2}')
        ;;     
        --skip-delete) skip_all_delete=1
        ;;
        --skip-delete-bp) skip_blueprint_delete=1
        ;;
        --skip-delete-policy) skip_policy_delete=1
        ;;
        --skip-assignment) skip_assignment_creation=1
        ;;
        --skip-assignment-file) skip_assignment_file_creation=1
        ;;
        --run-assignment) run_assignment_creation=1
        ;;
        --run-forcedelete) run_force_delete_policies=1
        ;;
	esac

	shift

done

}
