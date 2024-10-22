#!/usr/bin/env pwsh

<#
.SYNOPSIS
Runs a helm upgrade with the install flag in a dry run to attempt to compile the values to ensure things are correct
.Description
This script is designed to help you ensure the helm chart will install and read the required values correctly.

.PARAMETER help
Runs Get-Help -Full for the script

.EXAMPLE
# The script is designed to be just ran no flags are needed.
PS> .\Build-HelmChart.ps1 -localPathToChart ...


#> 

[CmdletBinding()]
Param (
  [Parameter(Mandatory=$true)] [ValidateNotNullOrEmpty()]
  [string]$localPathToChart,
  [Parameter(Mandatory=$false)]
  [string]$pathToHelmValues = $null
)




$pathToChart = [System.IO.DirectoryInfo]$localPathToChart

if(-not [string]::IsNullOrWhiteSpace($pathToHelmValues)){
  if(-not ([System.IO.FileInfo]$pathToHelmValues).Exists){
    Write-Error "Cannot find path to values file"
    exit
  }
}

if(-not $pathToChart.Exists){
  Write-Error "Chart Path not found"
  exit
}

$chartDrectory = $pathToChart.GetDirectories()[0]

if([string]::IsNullOrWhiteSpace($pathToHelmValues)){
  helm install $chartDrectory.Name $chartDrectory.FullName --dry-run --debug
  exit
}

helm upgrade --install $chartDrectory.Name $chartDrectory.FullName --dry-run --debug -f $pathToHelmValues