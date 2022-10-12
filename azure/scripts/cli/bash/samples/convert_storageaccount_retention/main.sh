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

if [ $dry_run -ne 0 ]; then
    echo "--dry-run flag set skipping all update/delete actions"
fi

if [ $dry_run -ne 0 ] && [ $apply_delete -ne 0 ]; then
    echo "--dry-run flag set apply with be ignored"
    apply_delete=0
fi

if [ $apply_delete -ne 0 ]; then
    echo "--apply flag set resource groups will be deleted"
fi

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

echo ""

source "${dir_path}/tasks/subscription.sh"

echo ""

