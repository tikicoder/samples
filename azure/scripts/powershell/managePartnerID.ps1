param(
	[string]$TenantId,
	[bool]$setPartnerID = $False
)

$NerderyPartnerID = 2209941

Set-AzContext -TenantId $TenantId > $null

Get-AzManagementPartner

if( $setPartnerID ){
	Write-Host "Partner ID Set to ${NerderyPartnerID}"
	new-AzManagementPartner -PartnerId $NerderyPartnerID
	
	#Update-AzManagementPartner -PartnerId $NerderyPartnerID
}