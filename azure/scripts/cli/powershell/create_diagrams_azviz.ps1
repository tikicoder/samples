# https://github.com/PrateekKumarSingh/AzViz

$start_Date = $(get-date)


$exclude_subscription_ids = @("75d7a572-e668-4ee5-a05d-e9434c462fe6")

foreach ( $subscription in $(az account subscription list | ConvertFrom-Json )){
    Set-AzContext -Subscription $subscription.subscriptionId
    write-host "$($subscription.subscriptionId) - $($subscription.displayName)"
    if ($exclude_subscription_ids.Contains($subscription.subscriptionId)) {
        write-host "Marked as Exclude: $($subscription.subscriptionId) - $($subscription.displayName)"
        continue
    }

    $rg_names = @()
    foreach ( $rg in $(az group list --subscription "$($subscription.subscriptionId)" | ConvertFrom-Json )){
        write-host "$($rg.name)"
        $rg_names += $rg.name

    }

    Export-AzViz -ResourceGroup $rg_names -Theme dark -OutputFormat svg -Show -LabelVerbosity 2 -OutputFilePath "$(Get-Location).Path/$($subscription.subscriptionId)-$($subscription.displayName).svg"
}

write-host $start_Date
write-host $(get-date)

