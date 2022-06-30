#.\deploy.ps1 "a39b7953-d913-4984-b454-a5b116d39d17" "rg-rt-AHCCCS" "westus2" "vnet-AHCCCS" "10.10.0.0/16"
param(
    [string]$subscription,
    [string]$resourceGroup,
    [string]$resourceLocation,
    [string]$virtualNetworkName,
    [string]$addressPrefixes,
    [string]$virtualNetworkPeerings = '[ ]',
    [bool]$enableDdosProtection = $False,
    [bool]$enableVmProtection = $False,
    [bool]$useWhatIfDeployment = $True,
    [bool]$forceDeployWhatIf = $False
    )

$baseFileName = "template"
$DeploymentName = "VNET"

$currentLocation = $(Get-Location)
Push-Location -Path $PSScriptRoot

$mainTemplatePath = $ExecutionContext.SessionState.Path.GetUnresolvedProviderPathFromPSPath("./")

Pop-Location

$templateFile = Join-Path -Path $mainTemplatePath -ChildPath "/${baseFileName}.json"

if( [string]::IsNullOrWhiteSpace($subscription) ){
    Write-Host "Subscription is required"
    exit;
}

Set-AzContext -SubscriptionId $subscription > $null

$objectVNetPeerings = [Newtonsoft.Json.JsonConvert]::DeserializeObject($virtualNetworkPeerings);
if( $objectVNetPeerings -eq $null){
    $objectVNetPeerings = @()
}

$deploymentParams = @{
    Name = "Deployment.${virtualNetworkName}.${DeploymentName}";
    Whatif         = $useWhatIfDeployment;
    ResourceGroupName       = $resourceGroup;
    TemplateFile            = $templateFile;
    resourceLocation        = $resourceLocation;
    virtualNetworkName      = $virtualNetworkName;
    virtualNetworkPeerings  = $objectVNetPeerings;
    addressPrefixes         = $addressPrefixes;
    enableDdosProtection    = $enableDdosProtection;
    enableVmProtection      = $enableVmProtection;
    
}

New-AzResourceGroupDeployment @deploymentParams

if( -NOT $useWhatIfDeployment ){
    exit;
}
    
    $deploymentParams.Remove('Whatif')
    $deploymentParams.Add("ResultFormat", "FullResourcePayloads")
    $results = Get-AzResourceGroupDeploymentWhatIfResult @deploymentParams
        
    if($results.Status -eq "Succeeded" ){
    
        $deploymentParams.Remove('ResultFormat')
        if ( -not $forceDeployWhatIf ){
            $deploymentParams.Add("Confirm", $True)
        }
        New-AzResourceGroupDeployment  @deploymentParams
        exit;
    }

    Write-Host $results.Error
