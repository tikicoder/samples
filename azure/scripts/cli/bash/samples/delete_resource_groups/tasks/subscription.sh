#!/bin/bash

function subscription_get_resource_group_names() {
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

if [ ! -z "${test_subscription_id}" ]; then
  subscription_info=$(echo "${subscription_info}" | jq -rc "[.[] | select(.key == \"$test_subscription_id\")]")
fi

for row in $(echo "${subscription_info}" | jq -r '.[] | @base64'); do
  subscription_id="$(parse_jq_decode $row '.key')"
  
  
  resource_group_names=$(subscription_get_resource_group_names $subscription_id)

  if [ $( echo "${resource_group_names}" | jq -r ". | length") -gt 0 ]; then
    echo "${subscription_id} - $(parse_jq_decode $row '.value')"

    echo $resource_group_names | jq -r ".[]"
    echo ""
    echo ""

    if [ $dry_run -ne 0 ] || [ $apply_delete -ne 1 ]; then
      continue
    fi

    for rg_name in $(echo "${resource_group_names}" | jq -r '.[]'); do
      echo $rg_name
      # az group delete  --no-wait -n "${rg_name}" --subscription $subscription_id 2>/dev/null
    done
     
  fi

done
