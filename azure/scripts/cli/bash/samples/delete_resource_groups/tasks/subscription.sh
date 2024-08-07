#!/bin/bash

function subscription_get_resources() {
  if [ -z "${filter_resource_group_names}" ]; then
    filter_resource_group_names="[]"
  fi
  
  local subscription_id=$1
  local local_resource_group_names='[]'
  local resource_group_list=$(az group list -o json --subscription $subscription_id 2>/dev/null)

  if [ -z "${resource_group_list}" ]; then
    echo $local_resource_group_names
    return
  fi

  if [ $(echo "${filter_resource_group_names}" | jq -r '. | length') -lt 1 ]; then
    local_resource_group_names=$(echo $resource_group_list | jq --argjson arr "${local_resource_group_names}" -rc "[ .[] | .name ] | unique")
    echo $local_resource_group_names
    return
  fi

  for filter_regex in $(echo "${filter_resource_group_names}" | jq -r '.[]'); do
    local_resource_group_names=$(echo $resource_group_list | jq --argjson arr "${local_resource_group_names}" -rc "[ .[] | select(.name|test(\"${filter_regex}\"; \"i\")) | .name ] | \$arr + . | unique")
  done

  echo $local_resource_group_names
}

echo ""

for row in $(echo "${subscription_info}" | jq -r '.[] | @base64'); do
  subscription_id="$(parse_jq_decode $row '.key')"
  
  
  resource_group_names=$(subscription_get_resources $subscription_id)

  if [ $( echo "${resource_group_names}" | jq -r ". | length") -gt 0 ]; then
    echo "${subscription_id} - $(parse_jq_decode $row '.value')"  

    for rg_name in $(echo "${resource_group_names}" | jq -r '.[]'); do
      
      if [ $dry_run -ne 0 ] || [ $apply_delete -ne 1 ]; then
        echo "     will delete $rg_name"
        continue
      fi
      echo "     deleting $rg_name"
      az group delete  --no-wait -y -n "${rg_name}" --subscription $subscription_id 2>/dev/null
    done

    echo ""
    echo ""
     
  fi

done
