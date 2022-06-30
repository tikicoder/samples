
Param(
    [Parameter(Mandatory = $true)][string] $SkipPrimary,
    [Parameter(Mandatory = $true)][string] $NoDeploymentSecondary,
    [Parameter(Mandatory = $true)][string] $SkipSecondary,
    [Parameter(Mandatory = $true)][string] $RESOURCE_GROUP,
    [Parameter(Mandatory = $true)][string] $APIM_PRIMARY,
    [Parameter(Mandatory = $true)][string] $PRODUCTID,
    [Parameter(Mandatory = $false)][string] $APIM_SECONDARY
)

if ( (-not ($NoDeploymentSecondary.ToString() -eq "false")) ){
    
    Write-Host "No Secondary Deployment: $NoDeploymentSecondary"    
    exit;
}

if ( (-not ($SkipPrimary.ToString() -eq "false")) -or (-not ($SkipSecondary.ToString() -eq "false")) ){
    
    Write-Host "##vso[task.logissue type=warning]Deployment was set to skip."

    Write-Host "Primary Skip - $SkipPrimary"
    Write-Host "Secondary Skip - $SkipSecondary"    
    exit;
}

Write-Host "APIM_PRIMARY: $($APIM_PRIMARY)"
Write-Host "APIM_SECONDARY: $($APIM_SECONDARY)"

. $PSScriptRoot/DeploymentCheck.ps1

if( $(IsNullOrEmptyResourceValue $APIM_PRIMARY) -or $(IsNullOrEmptyResourceValue $APIM_SECONDARY)){
    Write-Host "No Sync is required"
    Exit
}

$apimContextPrimary = New-AzApiManagementContext -ResourceGroupName $RESOURCE_GROUP -ServiceName $APIM_PRIMARY
$apimSubscriptionContextPrimary = Get-AzApiManagementSubscription -Context $apimContextPrimary -ProductId $PRODUCTID

$apimContextSecondary = New-AzApiManagementContext -ResourceGroupName $RESOURCE_GROUP -ServiceName $APIM_SECONDARY
$apimSubscriptionContextSecondary = Get-AzApiManagementSubscription -Context $apimContextSecondary -ProductId $PRODUCTID

Set-AzApiManagementSubscription -InputObject $apimSubscriptionContextSecondary -PrimaryKey $apimSubscriptionContextPrimary.PrimaryKey -SecondaryKey $apimSubscriptionContextPrimary.SecondaryKey