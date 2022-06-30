#/bin/bash

TenantId=$1
setPartnerID=false

if [ -z "$TenantId" ]; then
	echo "TenantId empty"
	exit;
fi

if [ $# -gt 1 ]
  then
    if [ "$2" == "1" ] | [ "$2" == "true" ]; then
		$setPartnerID=true
	fi
fi

$MSPartnerID = 000000 # replace 000000 with your msp partner id

az account list --refresh

SubscriptionID=$(az account list --query "[?tenantId == '${TenantId}']" | jq -r ".[0].id")
az account set -s $SubscriptionID

az managementpartner show

if [ $setPartnerID -eq true ]; then
	echo "Partner ID Set to ${MSPartnerID}"
	az managementpartner update --partner-id $MSPartnerID

fi
