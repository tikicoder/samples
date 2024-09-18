#!/usr/bin/env pwsh

param(
  [string]$tenantId = $null,
  [string]$subscriptionIdFilter = $null,
  [string]$subscriptionIdExclude = $null,
  [string]$remainingRequestHeaders = $null
)

$script_directory = $MyInvocation.MyCommand.Path | Split-Path -Parent

$arrTenantId = $null
if(-not [string]::IsNullOrWhiteSpace($tenantId)){
  if($tenantId.Length -gt 0){
    $arrTenantId = $tenantId.ToLower().split(",")
  } 
}
$arrSubscriptionIdFilter = $null
if(-not [string]::IsNullOrWhiteSpace($subscriptionIdFilter)){
  if($subscriptionIdFilter.Length -gt 0){
    $arrSubscriptionIdFilter = $subscriptionIdFilter.ToLower().split(",")
  } 
}
$arrSubscriptionIdExclude = $null
if(-not [string]::IsNullOrWhiteSpace($subscriptionIdExclude)){
  if($subscriptionIdExclude.Length -gt 0){
    $arrSubscriptionIdExclude = $subscriptionIdExclude.ToLower().split(",")
  } 
}

# https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/request-limits-and-throttling
$default_remaining_request_headers = "x-ms-ratelimit-remaining-subscription-reads"
# $default_remaining_request_headers = "x-ms-ratelimit-remaining-subscription-deletes,x-ms-ratelimit-remaining-subscription-reads,x-ms-ratelimit-remaining-subscription-writes," + `
#   "x-ms-ratelimit-remaining-tenant-reads,x-ms-ratelimit-remaining-tenant-writes,x-ms-ratelimit-remaining-subscription-resource-requests," + `
#   "x-ms-ratelimit-remaining-subscription-resource-entities-read,x-ms-ratelimit-remaining-tenant-resource-requests,x-ms-ratelimit-remaining-tenant-resource-entities-read"


if([string]::IsNullOrWhiteSpace($remainingRequestHeaders)){
  $remainingRequestHeaders = $default_remaining_request_headers
}
$arrRemainingRequestHeaders = $remainingRequestHeaders.split(",")

$requestUri = "https://management.azure.com/subscriptions/{0}/resourcegroups?api-version=2016-09-01"
$accessToken = "$((az account get-access-token | ConvertFrom-Json).accessToken)"
$requestHeaders = @{Authorization="Bearer $accessToken"}

$azureSubscriptions = $(az account list | ConvertFrom-Json)

foreach($subscription in $azureSubscriptions){
  if($subscription.state -ine "enabled"){
    continue
  }
  if($null -ne $arrTenantId){
    if(-not ($arrTenantId -contains $subscription.tenantId.ToLower())){
      continue
    } 
  }

  if($null -ne $arrSubscriptionIdFilter){
    if(-not ($arrSubscriptionIdFilter -contains $subscription.id.ToLower())){
      continue
    } 
  }

  if($null -ne $arrSubscriptionIdExclude){
    if(($arrSubscriptionIdExclude -contains $subscription.id.ToLower())){
      continue
    } 
  }
  
  Write-Host "Processing Subscription: $($subscription.id) ($($subscription.name))"
  $webRequestResponse = $(Invoke-WebRequest -Method GET -Headers $requestHeaders -Uri ([string]::Format($requestUri, $subscription.id.ToLower())))
  if($null -eq $webRequestResponse.Headers){
    Write-Host "No Response Headers - $($webRequestResponse.StatusCode)"
    continue
  }
  foreach($requestHeader in $arrRemainingRequestHeaders){
    Write-Host "$($requestHeader):"
    write-host "     $($webRequestResponse.Headers[$requestHeader])"

  }
}
