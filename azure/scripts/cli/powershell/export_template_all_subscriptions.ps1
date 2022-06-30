# ARM Template Viewer
# Ben Coleman
# https://marketplace.visualstudio.com/items?itemName=bencoleman.armview
$default_Main_template = '{
"$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
"contentVersion": "1.0.0.0",
"resources": [
],
"outputs": {}
}'

$default_rg_template = '{
"type": "Microsoft.Resources/deployments",
"apiVersion": "2021-04-01",
"name": "",
"resourceGroup": "demoResourceGroup",
"properties": {
    "mode": "Incremental",
    "template": { }
}
}'

$default_rg_subscription_template = '{
    "type": "Microsoft.Resources/deployments",
    "apiVersion": "2021-04-01",
    "name": "",
    "subscriptionId": "",
    "resourceGroup": "demoResourceGroup",
    "properties": {
        "mode": "Incremental",
        "template": { }
    }
}'

$default_deployment_resources = '{
    "$schema": "https://schema.management.azure.com/schemas/2019-04-01/deploymentTemplate.json#",
    "contentVersion": "1.0.0.0",
    "parameters": {},
    "resources": [],
    "variables": {}
}'

$start_Date = $(get-date)
$all_resource_deployment = $default_deployment_resources | ConvertFrom-Json
$tenant_template = $default_Main_template | ConvertFrom-Json
$tenant_id = $(az account show | ConvertFrom-Json ).tenantId

$exclude_subscription_ids = @("75d7a572-e668-4ee5-a05d-e9434c462fe6")

foreach ( $subscription in $(az account subscription list | ConvertFrom-Json )){
    write-host "$($subscription.subscriptionId) - $($subscription.displayName)"
    if ($exclude_subscription_ids.Contains($subscription.subscriptionId)) {
        write-host "Marked as Exclude: $($subscription.subscriptionId) - $($subscription.displayName)"
        continue
    }

    $all_resource_deployment_subscription = $default_deployment_resources | ConvertFrom-Json
    $subscription_template = $default_Main_template | ConvertFrom-Json

    foreach ( $rg in $(az group list --subscription "$($subscription.subscriptionId)" | ConvertFrom-Json )){
        write-host "$($rg.name)"
        
        do {        
            $template_resources = ""
            try {
                $template_resources = $(az group export --name "$($rg.name)" --subscription "$($subscription.subscriptionId)"  --skip-all-params)
                if ([string]::isNullorWhitespace($template_resources)){
                    continue
                }
            }
            catch {
                $template_resources = ""
                write-host $_.Exception
            }
        }
        while([string]::isNullorWhitespace($template_resources))

        $all_resource_deployment_subscription.resources += $( $template_resources | ConvertFrom-Json).resources 

        $subscription_resourceIndex = $subscription_template.resources.length
        $tenant_resourceIndex = $tenant_template.resources.length

        $subscription_template.resources += ($($default_rg_template | ConvertFrom-Json))
        $tenant_template.resources += ($($default_rg_subscription_template | ConvertFrom-Json))

        $subscription_template.resources[$subscription_resourceIndex].resourceGroup = $rg.name
        $subscription_template.resources[$subscription_resourceIndex].properties.template = $( $template_resources | ConvertFrom-Json)

        $tenant_template.resources[$tenant_resourceIndex].resourceGroup = $rg.name
        $tenant_template.resources[$tenant_resourceIndex].subscriptionId = $subscription.subscriptionId
        $tenant_template.resources[$tenant_resourceIndex].properties.template = $( $template_resources | ConvertFrom-Json)
        
    }

    $all_resource_deployment.resources += $all_resource_deployment_subscription.resources
    $subscription_template | ConvertTo-Json -Depth 100 > "$($subscription.subscriptionId)_$($subscription.displayName).json"
    $all_resource_deployment_subscription | ConvertTo-Json -Depth 100 > "resource_only_$($subscription.subscriptionId)_$($subscription.displayName).json"
}

$tenant_template | ConvertTo-Json -Depth 100 > "tenant_$($tenant_id).json"
    
$all_resource_deployment | ConvertTo-Json -Depth 100 > "resource_only_tenant_$($tenant_id).json"

write-host $start_Date
write-host $(get-date)

