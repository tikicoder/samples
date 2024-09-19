#!/usr/bin/env pwsh
# The space below is needed to ensure the Get-Help does not read the shebang

<#
.SYNOPSIS
Helps compare Helm Deployment versions between Kubernets
.Description
This script is designed to take an environment and a list of kubernets contexts. It will then go through and compare the helm deployment versions to see what is different

.EXAMPLE
# This will compare the contexts from Test with the contextes from compareTest
PS> .\main.ps1 -compareDetails '{"test":["context1","context2"], "compareTest":["contextCompare1"]}'
#> 

param(
    # a json Representation of the details. Example: '{"test":["context1","context2"], "compareTest":["contextCompare1"]}'
    [Parameter(Mandatory = $true)][string]$compareContextDetails,
    
    # a regex match on helm deployment names to compare
    [string]$deploymentNameRegex,

    # a regex match on helm deployment namespace to compare
    [string]$deploymentNamespaceRegex,

    # a regex match on helm deployment names to exclude
    [string]$excludeDeploymentNameRegex,

    # a regex match on helm deployment namespace to exclude
    [string]$excludeDeploymentNamespaceRegex,

    # a path to save output. Example Join-Path -Path [System.IO.Path]::GetTempPath() -ChildPath helmDeployments
    [string]$saveOutputPath = $null,

     # the main kubernetes context. If null the first one from compareContextDetails is used
     [Parameter(Mandatory = $false)][string]$mainContext = $null,

    # Displays Help
    [switch] $help
  
)

if(7 -gt $PSVersionTable.PSVersion.Major){
    throw "Powershell version 7.x or greater required"
}
  
if ($help -eq $true)
{
    Get-Help $PSCommandPath -Full
    exit
}


if($null -ieq $compareContextDetails){
    throw "compareContextDetails is required"
}

function Test-HelmDeployment{
    param(
        [string]$deploymentNameRegex,
        [string]$deploymentNamespaceRegex,
        [string]$excludeDeploymentNameRegex,
        [string]$excludeDeploymentNamespaceRegex,
        [System.Collections.Generic.Dictionary[string,hashtable]]$deploymentVersion,
        [string]$kubeContext,
        [switch]$isMainContext
    )
    
    $helmDeployments = (helm list -A -o json | ConvertFrom-Json -AsHashtable | Where-Object {
        (([string]::IsNullOrWhiteSpace($deploymentNameRegex) -or $_.name -imatch $deploymentNameRegex) -and ([string]::IsNullOrWhiteSpace($excludeDeploymentNameRegex) -or $_.name -inotmatch $excludeDeploymentNameRegex)) -and 
        (([string]::IsNullOrWhiteSpace($deploymentNamespaceRegex) -or $_.namespace -imatch $deploymentNamespaceRegex) -and ([string]::IsNullOrWhiteSpace($excludeDeploymentNamespaceRegex) -or $_.namespace -inotmatch $excludeDeploymentNamespaceRegex))})
    foreach($deployment in $helmDeployments){        
        $deploymentVersionKey = "$($deployment.namespace)-$($deployment.name)"
        if($null -ieq $deploymentVersion[$deploymentVersionKey]){
            $deploymentVersion[$deploymentVersionKey] = @{
                name = $deployment.name
                namespace = $deployment.namespace
                version = ($isMainContext ?($deployment.app_version) :$null)
                notInMain = (-not $isMainContext)
                versions = @{
                    $kubeContext = @{
                        name = $deployment.name
                        version = $deployment.app_version
                    }
                }
                mismatch = @{}
            }
            if(-not $isMainContext){
                $deploymentVersion[$deploymentVersionKey].mismatch[$kubeContext] = @{
                    name = $deployment.name
                    version = $deployment.app_version
                }
            }
            continue
        }

        $deploymentVersion[$deploymentVersionKey].versions[$kubeContext] = @{
            name = $deployment.name
            version = $deployment.app_version
        }

        if($deploymentVersion[$deploymentVersionKey].version -ieq $deployment.app_version){
            continue
        }
        $deploymentVersion[$deploymentVersionKey].mismatch[$kubeContext] = @{
            name = $deployment.name
            version = $deployment.app_version
        }
    }
}


$compareKubernetesContext = ($compareContextDetails | ConvertFrom-Json -AsHashtable)
if($null -ieq $compareKubernetesContext.Keys){
    throw "compareContextDetails is required - no Keys present"
}

$compareKubernetesContextKeys = ([string[]]$compareKubernetesContext.Keys)
if([string]::IsNullOrWhiteSpace($mainContext)){
    $mainContext = ($compareKubernetesContextKeys[0])
}
if($null -ieq $compareKubernetesContext[$mainContext]){
    throw "compareContextDetails is required - First Key contains no data"
}

$compareKubernetesContextMain = $compareKubernetesContext[$mainContext]
$compareKubernetesContext.remove($mainContext)

$deploymentVersion = New-Object System.Collections.Generic.Dictionary[string`,hashtable]

write-host "Processing Main Group: $($mainContext)"
foreach($kubernetesContext in $compareKubernetesContextMain){
    $null = (kubectl config use-context $kubernetesContext)
    
    Write-Host "Checking $($mainContext) - $($kubernetesContext)"
    $null = (Test-HelmDeployment `
        -deploymentNameRegex $deploymentNameRegex -deploymentNamespaceRegex $deploymentNamespaceRegex `
        -excludeDeploymentNameRegex $excludeDeploymentNameRegex -excludeDeploymentNamespaceRegex $excludeDeploymentNamespaceRegex `
        -deploymentVersion $deploymentVersion -isMainContext `
        -kubeContext $kubernetesContext)
}

foreach($environment in $compareKubernetesContext.GetEnumerator()){
    write-host "Processing: $($environment.Key)"
    foreach($kubernetesContext in $environment.Value){
        $null = (kubectl config use-context $kubernetesContext)

        Write-Host "Checking $($mainContext) - $($kubernetesContext)"
        $null = (Test-HelmDeployment `
            -deploymentNameRegex $deploymentNameRegex -deploymentNamespaceRegex $deploymentNamespaceRegex `
            -excludeDeploymentNameRegex $excludeDeploymentNameRegex -excludeDeploymentNamespaceRegex $excludeDeploymentNamespaceRegex `
            -deploymentVersion $deploymentVersion `
            -kubeContext $kubernetesContext)
    }
}
$deploymentsInError = @{}
$deploymentVersion.GetEnumerator() | Where-Object {[bool]::Parse($_.Value.notInMain) -or $_.Value.mismatch.Keys.Count -gt 0} | ForEach-Object{
    if($null -ieq $deploymentsInError[$_.Value.namespace]){
        $deploymentsInError[$_.Value.namespace] = @{}
    }
    $deploymentsInError[$_.Value.namespace][$_.Value.name] = $_.Value
}

Write-Host ""
Write-Host ""

if($deploymentsInError.Keys.Count -gt 0){
    Write-Host "The following Deployments are out of Sync"
    $deploymentErrorKeys = $deploymentsInError.Keys | Sort-Object
    foreach($deploymentKey in $deploymentErrorKeys){
        Write-Host "Namespace: $($deploymentKey)"
        foreach($deployment in $deploymentsInError[$deploymentKey].GetEnumerator()){            
            Write-Host "Name: $($deployment.Value.name)"
            Write-Host "notInMain: $($deployment.Value.notInMain)"
            Write-Host "version: $($deployment.Value.version)"
            foreach($mismatch in $deployment.Value.mismatch.GetEnumerator()){
                Write-Host "  context: $($mismatch.Key)"
                Write-Host "  version: $($mismatch.Value.version)"
    
            }
    
            Write-host ""
        }

        Write-host ""
        Write-host ""
    }
}

if([string]::IsNullOrWhiteSpace($saveOutputPath)){
    return
}

$saveOutputDirectory = ([System.IO.DirectoryInfo]$saveOutputPath)
if(-not $saveOutputDirectory.Exists){
    $saveOutputDirectory.Create()
    $saveOutputDirectory.Refresh()
}

Write-Host "Output will be saved to - $($saveOutputDirectory.FullName)"
$deploymentVersion | ConvertTo-Json -Depth 10  | Out-File -Path (Join-Path -Path $saveOutputDirectory.FullName -ChildPath fullDetails.json)
$deploymentsInError | ConvertTo-Json -Depth 10  | Out-File -Path (Join-Path -Path $saveOutputDirectory.FullName -ChildPath misMatch.json)