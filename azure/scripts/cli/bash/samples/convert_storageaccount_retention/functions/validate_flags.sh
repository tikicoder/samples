#!/bin/bash

function validate_flags_custom(){
  # work on system to allow spaces in key values
  case "$1" in  
    --filter-sanames=*) filter_storageaccount_names=$(echo $1  | awk -F= '{print $2}')
    ;;
  esac

}
