#!/bin/bash

function validate_flags(){
   while [ -n "$1" ]; do # while loop starts
    echo "working on $1"
    case "$1" in
        --env=*) app_environment=$(echo $1  | awk -F= '{print $2}')
        ;;
        --apply) tf_apply=1
        ;;
        --no-plan) tf_plan=0
        ;;
        --mg-only) run_management_group_only=1
        ;;
        --run-mg) run_management_group=1
        ;;
        --skip-hub) skip_hub=1
        ;;
        --skip-platform) skip_platform=1
        ;;
        --multi-process) multi_process_subscription=1
        ;;
        --tf-upgrade) tf_upgrade=1
        ;;
        --remove=*)
        tf_remove="${1#*=}"
        echo "Removing $tf_remove"
        ;;
        --dryrun) dryrun_flag=1
        ;;
	esac

	shift

done

}
