# This is a random list of oneliners or simple scripts that I need to organize

## Kubernetes

### BASH
#### Return Jsnn Array for each deployment that is the name, namespace and packageVersion label
kubectl get deployment -A -o=jsonpath="{range .items[*].metadata }[\"{.name}\",\"{.namespace}\",\"{.labels.packageVersion}\"]{'\n'}{end}"


#### Trigger a restart all deployments
kubectl get deploy -A -o json | jq -r "[.items | .[] | select(.metadata.namespace | ascii_downcase | startswith(`"platform-`")) | {name:.metadata.name, namespace: .metadata.namespace}]" | ConvertFrom-Json | ForEach-Object { kubectl rollout restart deployment -n $_.namespace $_.name}


#### Trigger a restart for all deployments in all AKSes
az aks list --subscription $subscription_id --query "[].{name:name, resourceGroup:resourceGroup}" | jq -rc ".[]" | while read -r aks; do
az aks get-credentials --subscription $subscription_id  -g "$(echo $aks | jq -r ".resourceGroup")" --name "$(echo $aks | jq -r ".name")" --admin --overwrite-existing
echo "Processing Restart for $(echo $aks | jq -r ".name") - $(echo $aks | jq -r ".resourceGroup")"
kubectl get deploy -A -o json | jq -rc "[.items | .[] | select(.metadata.namespace | ascii_downcase | startswith(\"platform-\")) | {name:.metadata.name, namespace: .metadata.namespace}] | .[]" | while read -r aks_deployment; do
echo "Rollout restart for deployment $(echo $aks_deployment | jq -r ".name") - $(echo $aks_deployment | jq -r ".namespace")"
kubectl rollout restart deployment -n  $(echo $aks_deployment | jq -r ".namespace")  $(echo $aks_deployment | jq -r ".name")
done

done


### Powershell 7.2+

### Return Jsnn Array for each deployment that is the name, namespace and packageVersion label
kubectl get deployment -A -o=jsonpath="{range .items[*].metadata }[`"{.name}`",`"{.namespace}`",`"{.labels.packageVersion}`"]{'\n'}{end}"


### Trigger a restart all deployments
(kubectl get deploy -A -o json | ConvertFrom-Json -Depth 20).items | Where-Object {$_.metadata.namespace.toLower().startsWith("platform-")} | ForEach-Object {kubectl rollout restart deployment -n $_.metadata.namespace $_.metadata.name}


