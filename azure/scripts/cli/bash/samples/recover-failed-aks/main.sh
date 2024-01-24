#!/bin/bash
# Script based on MS Doc https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/cluster-node-virtual-machine-failed-state

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

RED='\033[0;31m'
NC='\033[0m' # No Color

params_ok=1
echo $1
source "${dir_path}/common/general.sh"

if [ -z "$subscription_id" ]; then
  printf "${RED}Subscription ID was not passed in${NC}"
  echo ""
  params_ok=0
fi

if [ -z "$aks_resource_group" ]; then
  printf "${RED}AKS Subscription Group was not passed in${NC}"
  echo ""
  params_ok=0
fi

if [ -z "$aks_name" ]; then
  printf "${RED}AKS Name was not passed in${NC}"
  echo ""
  params_ok=0
fi


if [ $params_ok -lt 1 ]; then

echo "To run the script please pass in the subscription id, aks resource group, and aks name."
echo "${0} --subscription <subscriptionid> --resourcegroup <resourcegroup> --name <aksname>"
exit 1

fi

function update_aks_instances(){
  rg_node_aks="${aks_resource_group}-node-aks"
  (az vmss list --subscription $subscription_id -g $rg_node_aks --query "[].name" -o json) | jq -r ".[]" | while read -r vmss; do 
    (az vmss list-instances --subscription $subscription_id -g $rg_node_aks --name $vmss --query "[].instanceId" -o json) | jq -r ".[]" | while read -r instance; do 
      echo "Processing VMSS ${rg_node_aks} - ${vmss} - ${instance}"
      az vmss update-instances --subscription $subscription_id -g $rg_node_aks  --name $vmss --instance-id $instance
    done
  done
}

echo "Subscription: $subscription_id"
echo "AKS Resource Group: $aks_resource_group"
echo "AKS Name: $aks_name"


if [ $update_instances -gt 0 ]; then
  update_aks_instances
fi

if [ $update_instances_only -lt 1 ]; then
  echo "Processing AKS - ${aks_resource_group} ${aks_name}"
  az resource update --subscription $subscription_id --ids "/subscriptions/${subscription_id}/resourceGroups/${aks_resource_group}/providers/Microsoft.ContainerService/managedClusters/${aks_name}"
fi