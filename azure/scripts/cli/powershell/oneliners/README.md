# One Liners

# General Azure

### Ensure all Resource Providers in on Subscription are registered in the other subscription
$mainSubscription = "<mainSubID>"
$newSubscription = "<newSubID>>"
az provider list --subscription $mainSubscription | jq -r "[ .[] | select(.registrationState == `"Registered`") | .namespace ] " | ConvertFrom-Json | foreach{
	Write-Host "Namespace: $_"
	if(-not [bool]::Parse((az provider show --subscription $newSubscription --namespace $_ | jq -r ".registrationState == `"Registered`""))){
		az provider register --subscription $newSubscription --namespace $_
	}
}


### Generate Json Array of require resource providers
az provider list --subscription <mainSubID> | jq -r "[ .[] | select(.registrationState == `"Registered`") | .namespace ] "


# Helm

### Uninstall all platform packages
helm list -A -o json | ConvertFrom-Json -Depth 10 | Where-Object {$_.namespace.toLower().StartsWith("platform-")} | ForEach-Object { helm uninstall -n $_.namespace $_name}

## Kubernetes

### Return Jsnn Array for each deployment that is the name, namespace and packageVersion label
kubectl get deployment -A -o=jsonpath="{range .items[*].metadata }[`"{.name}`",`"{.namespace}`",`"{.labels.packageVersion}`"]{'\n'}{end}"


### Trigger a restart all deployments
(kubectl get deploy -A -o json | ConvertFrom-Json -Depth 20).items | Where-Object {$_.metadata.namespace.toLower().startsWith("platform-")} | ForEach-Object {kubectl rollout restart deployment -n $_.metadata.namespace $_.metadata.name}


