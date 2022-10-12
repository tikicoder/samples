#!/bin/bash

function subscription_get_resources() {
    
  local local_subscription_id=$1
  local local_filter=$2  

  if [ -z "${local_filter}" ]; then
    local_filter="[]"
  fi
  local local_resource_list=$(az storage account list -o json --subscription $local_subscription_id 2>/dev/null | jq -rc ".") 
  
  local_resource_list=$(base_subscription_get_resources "$local_resource_list" "$local_filter" "[ .[] | select(.sku.name|test(\"${filter_storageaccount_currentreplication}\", \"is\")) ]" "[ .[] | select(.sku.name|test(\"${filter_storageaccount_currentreplication}\", \"is\")) | select(.name|test(\$filter_regex, \"is\"))  ] | \$arr + . ")

  echo $local_resource_list | jq -rc "[ .[] | {\"id\":.id, \"name\":.name, \"resourceGroup\":.resourceGroup, \"sku_name\": .sku.name} ]"
}

for row in $(echo "${subscription_info}" | jq -r '.[] | @base64'); do
  subscription_id="$(parse_jq_decode $row '.key')"
  
  
  resource_list=$(subscription_get_resources $subscription_id $filter_storageaccount_names)
  
  if [ $( echo "${resource_list}" | jq -r ". | length") -lt 1 ]; then
    continue
  fi

  echo "${subscription_id} - $(parse_jq_decode $row '.value')"  
  for item in $(echo "${resource_list}" | jq -r '.[] | @base64'); do
    new_sku=$(echo "\"$(parse_jq_decode $item '.sku_name')\"" | jq -r ". | split(\"_\") | first | . + \"_${storageaccount_newreplication}\"")
    if [ $dry_run -ne 0 ] || [ $apply_delete -ne 1 ]; then
      echo "     will update $(parse_jq_decode $item '.name') from $(parse_jq_decode $item '.sku_name') to ${new_sku}"
      continue
    fi
    echo "     updating $(parse_jq_decode $item '.name') from $(echo "\"$(parse_jq_decode $item '.sku_name')\"" | jq -r ". | split(\"_\") | last") to ${new_sku}"
    # az storage account update \
    #   --name "$(parse_jq_decode $item '.name')"
    #   --resource-group "$(parse_jq_decode $item '.resourceGroup')" \
    #   --sku "${new_sku}" \
    #   --no-wait \
    #   --subscription $subscription_id 2>/dev/null
  done

  echo ""
  echo ""

done
