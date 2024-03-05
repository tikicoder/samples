#!/usr/bin/env pwsh

<#
.SYNOPSIS
Attempt to get the current size of a compiled pipeline in Azure DevOps
.Description
This script is designed to requrest the compiled yaml for a pipeline. It then attempts to calculate the size of the yaml file based on the compiled yaml returned
.PARAMETER organization
The Azure DevOps Organization where the pipeline exists

.PARAMETER project
The Azure DevOps Project under the Azure DevOps Organization where the pipeline Exists

.PARAMETER pipelineId
The Pipeline ID

.PARAMETER repoReference
The full reference to the branch to use, ie refs/heads/main

.PARAMETER help
Runs Get-Help -Full for the script

.EXAMPLE
# General
# This will attempt to use the branch users/rtruex/3032430-refactorpipeline and calculate on the pipeline 10611
PS> Get-PipelineYamlSize.ps1 -pipelineId 10611 -repoReference refs/heads/users/rtruex/3032430-refactorpipeline

#> 

param(
  [string]$organization = $null,  
  [string]$project = $null,

  
  [string]$pipelineId = $null,
  
  [string] $repoReference = $null,
  [switch] $help

)

if ($help -eq $true)
{
    Get-Help $MyInvocation.MyCommand.Path -Full
    exit
}

if([string]::IsNullOrWhiteSpace($organization)){
  Write-Error "Organization cannot be empty"
  Get-Help $MyInvocation.MyCommand.Path -Full
  exit 1
}

if([string]::IsNullOrWhiteSpace($organization)){
  Write-Error "Prganization cannot be empty"
  Get-Help $MyInvocation.MyCommand.Path -Full
  exit 1
}

if([string]::IsNullOrWhiteSpace($pipelineId)){
  Write-Error "Pipeline cannot be empty"
  Get-Help $MyInvocation.MyCommand.Path -Full
  exit 1
}

$defaultBodyJson = '{"previewRun": true, "templateParameters": {}, "resources":{"repositories":{"self":{"refName":"%refname%"}}}}'
$tmpStorageDirectroy = [System.IO.DirectoryInfo](Join-Path -Path ([System.IO.Path]::GetTempPath()) -Child "pipelineYamlSize")
if(-not $tmpStorageDirectroy.Exists){
  $tmpStorageDirectroy.Create()
}

$defaultBodyJson.Replace("%refname%", $repoReference) | Out-File -FilePath (Join-Path -Path $tmpStorageDirectroy.FullName -ChildPath "body.json")
Write-Host "project: $project"
Write-Host "organization: $organization"
Write-Host "pipelineId: $pipelineId"

az devops invoke --area pipelines --resource preview --api-version 7.1 --http-method post `
  --route-parameters pipelineId=$pipelineId project="$($project)" --organization "$($organization)" `
  --in-file (Join-Path -Path $tmpStorageDirectroy.FullName -ChildPath "body.json") | ConvertFrom-Json | Select-Object {$_.finalYaml.length/1024/1024}

$tmpStorageDirectroy.Delete($true)