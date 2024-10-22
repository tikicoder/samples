#!/usr/bin/env pwsh
<#
.SYNOPSIS
Help Migrating Node settings 

.DESCRIPTION
Some settings are immutable and cannot be change post creation. This helps allow you to update the existing node by creating a temp node to move the existing pods too and then recreats the old node(s) with the correct settings


.NOTES
This is a standalone file at the moment and is a sarting point that could be evolved some

#>

$aks_region="..."
$aks_environment="..."
$aks_rg="rg-${aks_environment}-${aks_region}"
$aks_instance="aks-${aks_environment}-${aks_region}"
$aks_systemnode="system"
$aks_usernode="user01"

kubectl ctx "$($aks_instance)-admin"

az aks nodepool add --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance -n systemtmp --mode System --node-vm-size Standard_D2ads_v5 --os-type Linux --os-sku AzureLinux --node-osdisk-type Ephemeral --node-osdisk-size 65 --zones 1 2 3 --node-count 2 --min-count 2 --max-count 4 --max-pods 30 --max-surge 33% --enable-cluster-autoscaler # --node-taints CriticalAddonsOnly=true:NoSchedule

(kubectl get nodes -o json | ConvertFrom-Json -Depth 10).items | ForEach-Object {$_.metadata.name} | Where-Object {$_ -ilike "*-$($aks_systemnode)-*"} | ForEach-Object { kubectl cordon $_ }
(kubectl get nodes -o json | ConvertFrom-Json -Depth 10).items | ForEach-Object {$_.metadata.name} | Where-Object {$_ -ilike "*-$($aks_usernode)-*"} | ForEach-Object { kubectl cordon $_ }

(kubectl get nodes -o json | ConvertFrom-Json -Depth 10).items | ForEach-Object {$_.metadata.name} | Where-Object {$_ -ilike "*-$($aks_systemnode)-*"} | ForEach-Object { kubectl drain --ignore-daemonsets --delete-emptydir-data $_ }
(kubectl get nodes -o json | ConvertFrom-Json -Depth 10).items | ForEach-Object {$_.metadata.name} | Where-Object {$_ -ilike "*-$($aks_usernode)-*"} | ForEach-Object { kubectl drain --ignore-daemonsets --delete-emptydir-data $_ }


Write-Host "Delete $($aks_systemnode) Node Pool"
az aks nodepool delete --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance -n $aks_systemnode --no-wait

Write-Host "Delete $($aks_usernode) Node Pool"
az aks nodepool delete --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance -n $aks_usernode

az aks nodepool list --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance --query "[].name"

az aks nodepool add --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance -n $aks_systemnode --mode System --node-vm-size Standard_D2ads_v5 --os-type Linux --os-sku AzureLinux --node-osdisk-type Ephemeral --node-osdisk-size 65 --zones 1 2 3 --node-count 2 --min-count 2 --max-count 4 --max-pods 30 --max-surge 33% --enable-cluster-autoscaler --no-wait # --node-taints CriticalAddonsOnly=true:NoSchedule

az aks nodepool add --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance -n $aks_usernode --mode User --node-vm-size Standard_D4ads_v5 --os-type Linux --os-sku AzureLinux --node-osdisk-type Ephemeral --node-osdisk-size 120 --zones 1 2 3 --node-count 1 --min-count 1 --max-count 4 --max-pods 90 --max-surge 33% --enable-cluster-autoscaler

az aks nodepool list --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance --query "[].name"

(kubectl get nodes -o json | ConvertFrom-Json -Depth 10).items | ForEach-Object {$_.metadata.name} | Where-Object {$_ -ilike "*-systemtmp-*"} | ForEach-Object { kubectl cordon $_ }
(kubectl get nodes -o json | ConvertFrom-Json -Depth 10).items | ForEach-Object {$_.metadata.name} | Where-Object {$_ -ilike "*-systemtmp-*"} | ForEach-Object { kubectl drain --ignore-daemonsets --delete-emptydir-data $_ }
az aks nodepool delete --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance -n systemtmp
