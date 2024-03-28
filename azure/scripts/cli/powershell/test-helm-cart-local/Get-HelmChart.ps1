#!/usr/bin/env pwsh

<#
.SYNOPSIS
Downloads a helm chart untarred
.Description
This script is designed to download a helm chart from the Azure ACR. It will download it to a temp location and have it untarred for viewing. You can specify a version if none is done the lastest is used.

.PARAMETER help
Runs Get-Help -Full for the script

.EXAMPLE
# The script is designed to be just ran no flags are needed.
PS> .\Build-HelmChart.ps1 -localPathToChart ...


#> 

[CmdletBinding()]
Param (
  [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]
  [string]$subscription,
  [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]
  [string]$containerRegistryServer,
  [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]
  [string]$pathToPackage,
  [ValidateNotNullOrEmpty()]
  [string]$version = "latest"
  

)


$acrAuthTokenRaw = $(az acr login --subscription $subscription --name $containerRegistryServer --expose-token)
$acrAuthToken = $($acrAuthTokenRaw | ConvertFrom-Json -Depth 10)
$acrAuthToken.accessToken | helm registry login $acrAuthToken.loginServer `
  --username "00000000-0000-0000-0000-000000000000" `
  --password-stdin

$savePath = [System.IO.DirectoryInfo](Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath ([System.IO.Path]::GetRandomFileName()))
if(-not $savePath.Exists){
  $savePath.Create()
}

helm pull oci://$($containerRegistryServer).azurecr.io/$pathToPackage --untar --untardir $savePath.FullName --version $version

Write-Host "Helm Chart has been downloaded to $($savePath.FullName)"