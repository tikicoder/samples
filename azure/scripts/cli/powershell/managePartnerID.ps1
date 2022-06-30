param(
	[string]$TenantId,
	[bool]$setPartnerID = $False
)

# This script is to help MSP to add their MSP ID to client accounts

$MSPartnerID = 000000 # replace 000000 with your msp partner id
$homeTenantId = "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx"
az account list --refresh

$SubscriptionID = $(az account list --query "[?homeTenantId == '${homeTenantId}']" | ConvertFrom-Json)[0].id
az account set -s $SubscriptionID > $null

az managementpartner show | ConvertFrom-Json

if( $setPartnerID ){
	Write-Host "Partner ID Set to ${MSPartnerID}"
	az managementpartner update --partner-id $NerderyPartnerID

}
