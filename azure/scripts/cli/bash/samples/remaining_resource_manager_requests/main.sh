#!/bin/bash
if [ ! $(command -v "realpath") ]; then
  realpath() {
  OURPWD=$PWD
  cd "$(dirname "$1")"
  LINK=$(readlink "$(basename "$1")")
  while [ "$LINK" ]; do
    cd "$(dirname "$LINK")"
    LINK=$(readlink "$(basename "$1")")
  done
  REALPATH="$PWD/$(basename "$1")"
  cd "$OURPWD"
  echo "$REALPATH"
  }
fi

full_path=$(realpath $0)
dir_path=$(dirname $full_path)
parent_path=$(realpath "${dir_path}/../")
root_path=$parent_path

while [ ! -f "${root_path}/_root" ]; 
do
  root_path=$(realpath "${root_path}/../")
done

source "${root_path}/common/general.sh"


if [ ! -z "${tenant_id}" ]; then
  subscription_info=$(az account list --query "[?homeTenantId == '${tenant_id}']" | jq -r -c "[.[] | {(.id):.name}]")
else
  subscription_info=$(az account list | jq -r -c "[.[] | {(.id):.name}]")
fi

subscription_info=$(echo $subscription_info | jq -r " [.[]  | to_entries | add]")

if [ ! -z "${subscription_filter}" ]; then
  subscription_info=$(echo "${subscription_info}" | jq --argjson sub_include "$(split_string_jq "${subscription_filter}")" -rc "[.[] | select(.key | IN(\$sub_include[])) ]")
fi

if [ ! -z "${subscription_exclude}" ]; then
  subscription_info=$(echo "${subscription_info}" | jq --argjson sub_include "$(split_string_jq "${subscription_exclude}")" -rc "[.[] | select(.key | IN(\$sub_include[])) ]")
fi

if [ ! -z "${test_subscription_id}" ]; then
  subscription_info=$(echo "${subscription_info}" | jq -rc "[.[] | select(.key == \"$test_subscription_id\")]")
fi

if [ -z "$(trim_string $remaining_request_headers)" ]; then
  remaining_request_headers=$(echo "${default_remaining_request_headers}")
fi

remaining_request_headers="$(split_string_jq "${remaining_request_headers}")"

# list of all headers
path_msdoc="https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/request-limits-and-throttling#remaining-requests"

request_uri="https://management.azure.com/subscriptions/{subscription}/resourcegroups?api-version=2016-09-01"
access_token="$(az account get-access-token --query accessToken --output tsv)"

response_headers_file=$(mktemp)

for row in $(echo "${subscription_info}" | jq -r '.[] | @base64'); do
  subscription_id="$(parse_jq_decode $row '.key')"
  echo "Subscription: ${subscription_id} ($(parse_jq_decode $row '.value'))"
  curl -s -I -X GET --header "Authorization: Bearer $access_token" "$(echo $request_uri | sed -e "s/{subscription}/$subscription_id/")" | cat > $response_headers_file
  echo "" | cat >> $response_headers_file # this seems key otherwise it does more in the file then needed

  for remaining_req_header in $(echo "${remaining_request_headers}" | jq -r '.[]'); do
    remaining_req_header="$(echo "$remaining_req_header" | tr '[:upper:]' '[:lower:]')"
    echo "    $(trim_string "$(cat $response_headers_file | grep -i "${remaining_req_header}" | awk -F':' '{print $2}')")"
  done
done

if [ -f "${response_headers_file}" ]; then
  rm $response_headers_file
fi