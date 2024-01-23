#!/usr/bin/env pwsh

<#
.SYNOPSIS
TRy to have AKS recover from a failed state
.Description
The goal of this script is to try to get AKS to recover from a failed state. This will be a wip.
Script is based on MS Doc https://learn.microsoft.com/en-us/troubleshoot/azure/azure-kubernetes/cluster-node-virtual-machine-failed-state
.PARAMETER subscription
The subscription that all commands should run against

.PARAMETER resourcegroup
The resourcegroup for where the AKS is

.PARAMETER name
The name of the AKS resource

.PARAMETER help
Runs Get-Help -Full for the script

.EXAMPLE
# This will run the script on the int euno location
PS> .\Start-AksRecovery.ps1 -subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -resourcegroup "rg-int-euno" -name "aks-int-euno"

#> 

param
(
    [Parameter(Mandatory)] [string]$subscription,
    [Parameter(Mandatory)] [string]$resourceGroup,
    [Parameter(Mandatory)] [string]$name,
    [switch] $updateVMInstances,
    [switch] $updateVMInstancesOnly,
    [switch] $help
)

if ($help -eq $true)
{
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit
}

Write-Host "Subscription: $subscription"
Write-Host "AKS Resource Group: $resourcegroup"
Write-Host "AKS Name: $name"

if (
  [string]::IsNullOrWhiteSpace($subscription) -or
  [string]::IsNullOrWhiteSpace($resourcegroup) -or
  [string]::IsNullOrWhiteSpace($name)
  ){
  
  Write-Error "Subscription, Resource Group, or AKS Name is empty"
  Get-Help $MyInvocation.MyCommand.Path -Full
  exit 1
}

function Update-AKSInstance{
  $rgNodeAKS = "$($resourceGroup)-node-aks"
  (az vmss list --subscription $subscription -g $rgNodeAKS --query "[].name" -o json | ConvertFrom-Json) | ForEach-Object {

    $instances = (az vmss list-instances --subscription $subscription -g $rgNodeAKS  --name $_ --query "[].instanceId" -o json | ConvertFrom-Json)

    foreach($instance in $instances){
      Write-Host "Processing VMSS $($rgNodeAKS) - $($_) - $($instance)"
      az vmss update-instances --subscription $subscription -g $rgNodeAKS  --name $_ --instance-id $instance
    }

  }
}

if(-not $updateVMInstancesOnly){
  Write-Host "Processing AKS - $($resourcegroup) $($name)"
  az resource update --subscription $subscription --ids /subscriptions/$subscription/resourceGroups/$resourcegroup/providers/Microsoft.ContainerService/managedClusters/$name
}

if($updateVMInstances -or $updateVMInstancesOnly){
  Update-AKSInstance
}