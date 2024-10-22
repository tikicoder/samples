#!/usr/bin/env pwsh
<#
.SYNOPSIS
General common library of functions

.DESCRIPTION
This file needs to get migrates to the main common.ps1.


#>

function Get-CurrentUserIDSPN {
  $objectId = $Null
  $spn_lookup = $(az ad sp list --spn "$($currentUser.name)" | ConvertFrom-Json)
  if($spn_lookup -is [array]){
    $objectId = ($spn_lookup[0].objectId)  
    if($null -ne $objectId){
      return $objectId
    }
    $objectId = ($spn_lookup[0].id)  
    if($null -ne $objectId){
      return $objectId
    }
    
  }
  else {
    
    $objectId = ($spn_lookup.objectId)  
    if($null -ne $objectId){
      return $objectId
    }
    $objectId = ($spn_lookup.id)  
    if($null -ne $objectId){
      return $objectId
    }
  }
  
  $spn_lookup = $(az ad sp list --display-name "$($currentUser.name)" | ConvertFrom-Json)
  if($spn_lookup -is [array]){
    $objectId = ($spn_lookup[0].objectId)  
    if($null -ne $objectId){
      return $objectId
    }
    $objectId = ($spn_lookup[0].id)  
    if($null -ne $objectId){
      return $objectId
    }
    
  }
  else {
    
    $objectId = ($spn_lookup.objectId)  
    if($null -ne $objectId){
      return $objectId
    }
    $objectId = ($spn_lookup.id)  
    if($null -ne $objectId){
      return $objectId
    }
  }
  
  if($null -ne $objectId){
    return $objectId
  }

  throw "Could not find SPN Object ID"
}

function Get-CurrentUserID {
  $currentUser = (az account show | ConvertFrom-Json).user 
  if($null -eq $currentUser){
    return $currentUser
  }

  if($currentUser.type -ieq "user")
  {
    return @{
      "type" = "objectId"
      "value" = ((az ad signed-in-user show | ConvertFrom-Json).id)
    }
  }

  if($currentUser.type -ieq "servicePrincipal")
  {
    return @{
      "type" = "objectId"
      "value" = (Get-CurrentUserIDSPN)
    }
  }

  throw "Unknown User Type - $($currentUser.type)"

  #type servicePrincipal
}

function Update-AzureCLIFresh{
  param(
    [System.Version]$requiredCLIVeresion
  )
  $azureCLIVersion = ([System.Version](az version | ConvertFrom-JSON)."azure-cli")
  $maxMinorVersionDifference = 10

  if ($IsWindows){
    if($azureCLIVersion.Major -lt $requiredCLIVeresion.Major -or ($requiredCLIVeresion.Minor - $azureCLIVersion.Minor) -gt $maxMinorVersionDifference ){
      $cliDirectory =([System.IO.DirectoryInfo](split-Path -Parent (Split-Path -Parent (get-command az).Source)))
      if($cliDirectory.Name.ToLower().StartsWith("cli")){
        $cliDirectory.Delete($true)
      }
    }
    $ProgressPreference = 'SilentlyContinue'; Invoke-WebRequest -Uri https://aka.ms/installazurecliwindows -OutFile .\AzureCLI.msi; Start-Process msiexec.exe -Wait -ArgumentList '/I AzureCLI.msi /quiet'; Remove-Item .\AzureCLI.msi
    return
  }

  if($IsLinux){
    throw "unsure how to fresh install on linux"
  }

  if($IsMacOS){
    throw "unsure how to fresh install on IsMacOS"
  }

  throw "unknown OS - Requires PSCore 7+ ($($PSVersionTable.PSVersion.Major))"
}

function Update-AzureCLI{
  param(
    [System.Version]$requiredCLIVeresion
  )
  
  $azureCLIVersion = ([System.Version](az version | ConvertFrom-JSON)."azure-cli")
  Debug-LogMessage -LogLevel 'Host' -LogMessage "Current CLI verion: ($($azureCLIVersion)) - required ($($requiredCLIVeresion))"
  $maxMinorVersionDifference = 5
  if($azureCLIVersion -lt $requiredCLIVeresion){
    Debug-LogMessage -LogLevel 'Host' -LogMessage "Current CLI verion: ($($azureCLIVersion)) is older than required ($($requiredCLIVeresion))"
    if($azureCLIVersion.Major -lt $requiredCLIVeresion.Major -or ($requiredCLIVeresion.Minor - $azureCLIVersion.Minor) -gt $maxMinorVersionDifference ){
      Debug-LogMessage -LogLevel 'Host' -LogMessage "Either the Major Version changed or more than $($maxMinorVersionDifference) Minor updates newer"
      Debug-LogMessage -LogLevel 'Host' -LogMessage "Performing new install vs upgrade"
      Update-AzureCLIFresh -requiredCLIVeresion $requiredCLIVeresion
    }
    
    Debug-LogMessage -LogLevel 'Host' -LogMessage "Ensuring all components upgraded"
    az upgrade --yes --all 
  }

  Debug-LogMessage -LogLevel 'Host' -LogMessage "Current Azure CLI Version $((az version | ConvertFrom-JSON)."azure-cli")"
}

function Debug-LogMessage{
  param(
    [ValidateSet('Verbose', 'Warning', 'Host', 'Error')]
    [string]$LogLevel,
    [string]$LogMessage,
    [switch]
    $ExcludeTimestamp
  )

  if (-not $ExcludeTimestamp) {
    $LogMessage = ("{0} " -f (Get-Date).ToString("yyyy-MM-dd HH:mm:ss.ffff")) +  $LogMessage
  }
  if ($LogLevel -eq 'Host') {
      Write-Host $LogMessage
  }
  elseif ($LogLevel -eq 'Verbose') {
      Write-Verbose -Message $LogMessage
  }
  elseif ($LogLevel -eq 'Warning') {
      Write-Host "##vso[task.logissue type=warning;]$($LogMessage)"
      Write-Warning -Message $LogMessage
  }
  elseif ($LogLevel -eq 'Error'){
      Write-Host "##vso[task.logissue type=error;]$($LogMessage)"
      Write-Error -Message $LogMessage -ErrorAction Continue
  }
  
}

function Save-ArtifactData{
  param(
    [string]$savePath,
    [hashtable]$data
  )  

  $data | ConvertTo-Json -Depth 20 | Out-File -FilePath $savePath
}

function Set-AzurePSContext{
  
  param(
    [string]$subscriptionId
  )

  if($testMode){
    Debug-LogMessage -LogLevel 'Host' -LogMessage "Set Context"
  }
  
  Set-AzContext -SubscriptionId $subscriptionId > $null
}

function Connect-AZPowerShellCLI{
  
  param(
    [string]$subscriptionId
  )

  if($testMode){
    Debug-LogMessage -LogLevel 'Host' -LogMessage "Connecting"
  }
  
  $cleanAzurePSCreds = $true
  Connect-AzAccount -MicrosoftGraphAccessToken $(az account get-access-token --resource-type ms-graph --query accessToken --output tsv) -GraphAccessToken $(az account get-access-token --resource-type aad-graph --query accessToken --output tsv) -KeyVaultAccessToken $(az account get-access-token --resource https://vault.azure.net --query accessToken --output tsv)  -AccessToken $(az account get-access-token --query accessToken --output tsv) -AccountId $(Get-CurrentUserID) > $null
  Set-AzurePSContext -subscriptionId $subscriptionId
}