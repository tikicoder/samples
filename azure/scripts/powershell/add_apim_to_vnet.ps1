param([string]$REGION,[string]$ENVIRONMENT,[string]$SUBSCRIPTION_ID)

$vnet = New-AzApiManagementVirtualNetwork -SubnetResourceId "/subscriptions/$SUBSCRIPTION_ID/resourceGroups/Sample-$ENVIRONMENT-network-rg/providers/Microsoft.Network/virtualNetworks/Sample-$ENVIRONMENT-vnet/subnets/Sample-$ENVIRONMENT-apim-subnet"
$apimServiceGet = Get-AzApiManagement -ResourceGroupName Sample-$ENVIRONMENT-apim-rg -Name Sample-$ENVIRONMENT-apim
$apimServiceGet.VpnType = "External"
$apimServiceGet.VirtualNetwork = $vnet
Set-AzApiManagement -InputObject $apimServiceGet
