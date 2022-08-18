#!/bin/bash

# Possible option for display via progress bar instead of sub ids
# https://stackoverflow.com/questions/48251101/multiprocess-with-shared-variable-in-bash

accounts=$(az account list -o json)
vnets="{}"
subscriptions="{}"
count=0
for row in $(echo "${accounts}" | jq -r '.[] | @base64'); do
  count=$((count+1))
  _jq() {
    echo ${row} | base64 --decode | jq -r ${1}
  }

  echo "Processing Account $(_jq '.id')"
  single_account_data=$(az network vnet list --subscription $(_jq '.id') | jq -r '.[] | {(.id): .}')
  vnets=$((echo $vnets; echo $single_account_data) | jq -s add)
  # subscriptions=$((echo $subscriptions; echo $row) | jq -s add)

  # break for testing
  # if [ $count -gt 2 ]; then
  #   break
  # fi

done

echo ""
echo ""
count=0
for row_vnet in $(echo "${vnets}" | jq -r ". | keys | .[] | @base64"); do
  count=$((count+1))
  _jq() {
    echo ${row_vnet} | base64 --decode 
  }

  echo "Processing VNET $(_jq )"

  echo "vnet Name: $(echo "${vnets}" | jq -r ".\"$(_jq )\" | .name")"  
  subscription_id=$(echo "\"$(_jq_peer '.id' )\"" | jq -r '. | split("/")[2]')
  echo "Subscription: $(az account show --subscription ${subscription_id} | jq -r ".name" )"

  for row_vnet_peer in $(echo "${vnets}" | jq -r ".\"$(_jq )\" | .virtualNetworkPeerings | .[] | @base64"); do
    count=$((count+1))
    _jq_peer() {
      echo ${row_vnet_peer} | base64 --decode | jq -r ${1}
    }

    echo "Peering Name: $(_jq_peer '.name' )"

    subscription_id=$(echo "\"$(_jq_peer '.remoteVirtualNetwork.id' )\"" | jq -r '. | split("/")[2]')
    echo "Remote Subscription: $(az account show --subscription ${subscription_id} | jq -r ".name" )"
    echo ""
  done
  echo ""
  echo ""
done
