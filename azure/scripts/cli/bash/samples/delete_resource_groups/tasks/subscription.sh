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

for row in $(echo "${subscription_info}" | jq -r '. [] | @base64'); do
  subscription_id="$(parse_jq_decode $row '.key')"
  
  
  resource_group_names=$(subscription_get_resource_group_names $subscription_id)

  if [ $( echo "${resource_group_names}" | jq -r ". | length") -gt 0 ]; then
    if [ $dry_run -ne 0 ]; then
      echo "${subscription_id} - $(parse_jq_decode $row '.value')"

      echo $resource_group_names | jq -r ".[]"
      echo ""
      echo ""
      continue
    fi
  fi

done


# for row in $(echo "${subscription_info}" | jq -r '. [] | @base64'); do
#   subscription_id="$(parse_jq_decode $row '.key')"
#   echo "processing subscriptions id - ${subscription_id}:"
#   if [ ! -z "${test_subscription_id}" ]; then
#     subscription_id="${test_subscription_id}"
#   fi
  
#   if [ $delete_existing_remediation_tasks -eq 1 ]; then
#     remediation_list=$(az policy remediation list --subscription $subscription_id  2>/dev/null)
#     if [ ! -z "${remediation_list}" ]; then
#       remediation_list=$(echo ${remediation_list}| jq -rc )

#       for row_remediation in $(echo "${remediation_list}" | jq -r '. [] | @base64'); do
#         if [ $dry_run -eq 1 ]; then
#           echo "dry run: "
#           echo "  az policy remediation delete --subscription $subscription_id --name \"$(parse_jq_decode $row_remediation '.name')\""
#           echo ""
#           echo "---------------------"
#           echo ""
#           continue
#         fi
#         az policy remediation delete --subscription $subscription_id --name "$(parse_jq_decode $row_remediation '.name')"
#       done
#     fi
#   fi

#   policy_assignment_ids=$(subscription_get_policy_assignment_ids $subscription_id)
#   if [ ! -z "${policy_assignment_ids}" ]; then
#     if [ $(echo $policy_assignment_ids | jq -r ". | length") -lt 1 ]; then
#       continue
#     fi
    
#     for policy_assignment_id in $(echo "${policy_assignment_ids}" | jq -r '. []'); do
#       id_only=$(echo $(split_string_jq $policy_assignment_id "/") | jq -r ". | last" )
#       if [ $dry_run -eq 1 ]; then
#         echo "dry run: "
#         echo "  az policy remediation create --subscription $subscription_id -n \"${id_only} - Remediation - $(date -u +"%Y%m%dT%H%M$S")Z\" --policy-assignment $policy_assignment_id"
#         echo ""
#         echo "---------------------"
#         echo ""
#         continue
#       fi
#       az policy remediation create --subscription $subscription_id -n "${id_only} - Remediation - $(date -u +"%Y%m%dT%H%M$S")Z" --policy-assignment $policy_assignment_id &
#     done
#   fi
#   if [ ! -z "${test_subscription_id}" ]; then
#     break
#   fi
  

# done
