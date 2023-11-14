aks_rg="..."
aks_instance="..."
aks_systemnode="system"
aks_usernode="user"

az aks nodepool add --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance -n systemtmp --mode System --node-vm-size Standard_D2ads_v5 --os-type Linux --os-sku AzureLinux --node-osdisk-type Ephemeral --node-osdisk-size 65 --zones 1 2 3 --node-count 2 --min-count 2 --max-count 4 --max-pods 30 --max-surge 33% --enable-cluster-autoscaler # --node-taints CriticalAddonsOnly=true:NoSchedule

k get nodes | grep -i "\-${aks_systemnode}\-" | awk -F' ' '{print $1}' | xargs kubectl cordon
k get nodes | grep -i "\-${aks_usernode}\-" | awk -F' ' '{print $1}' | xargs kubectl cordon
k get nodes | grep -i "\-${aks_systemnode}\-" | awk -F' ' '{print $1}' | xargs kubectl drain --ignore-daemonsets --delete-emptydir-data
k get nodes | grep -i "\-${aks_usernode}\-" | awk -F' ' '{print $1}' | xargs kubectl drain --ignore-daemonsets --delete-emptydir-data

az aks nodepool delete --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance -n user01
az aks nodepool delete --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance -n system

az aks nodepool add --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance -n "${aks_systemnode}" --mode System --node-vm-size Standard_D2ads_v5 --os-type Linux --os-sku AzureLinux --node-osdisk-type Ephemeral --node-osdisk-size 65 --zones 1 2 3 --node-count 2 --min-count 2 --max-count 4 --max-pods 30 --max-surge 33% --enable-cluster-autoscaler # --node-taints CriticalAddonsOnly=true:NoSchedule

az aks nodepool add --subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance -n "${aks_usernode}" --mode User --node-vm-size Standard_D4ads_v5 --os-type Linux --os-sku AzureLinux --node-osdisk-type Ephemeral --node-osdisk-size 120 --zones 1 2 3 --node-count 1 --min-count 1 --max-count 4 --max-pods 90 --max-surge 33% --enable-cluster-autoscaler

az aks nodepool delete -subscription 5c49443f-ce4b-470d-8ba8-c9571c1de06d -g $aks_rg --cluster-name $aks_instance -n systemtmp
