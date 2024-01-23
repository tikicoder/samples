#!/bin/bash
update_instances=0
update_instances_only=0
function validate_flags(){
  # work on system to allow spaces in key values
  while [ -n "$1" ]; do # while loop starts
    case "$1" in    
      --subscription) 
        shift
        subscription_id=$1
      ;;
      --resource-group) 
        shift
        aks_resource_group=$1
      ;;
      --name) 
        shift
        aks_name=$1
      ;;
      --update-instances) 
        shift
        update_instances=1
      ;;
      --update-instances-only) 
        shift
        update_instances_only=1
        update_instances=1
      ;;
    esac

    shift

  done

}