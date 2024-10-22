#!/usr/bin/env pwsh

<#
.SYNOPSIS
Help clean up Azure RBAC permissions
.Description
This script is designed to go through every subscription that you have access to via the CLI and determine which Identities no longer exists.
The PARAMETER artifactSavePath is requrired
.PARAMETER artifactSavePath
The location where the json file with the details oh what identities will be deleted or where deleted depending on if testmode is true or false
This cannot be empty
The file is stored in a subDirectory "unknownIdentity"
This is always created

.PARAMETER subscriptionIdsStr
A comma seperated list of subscription ids to include

.PARAMETER excludeSubscriptionIdsStr
A comma seperated list of subscription ids to exinclude

.PARAMETER verbose
Output mode verbose

.PARAMETER cleanup
Should the clean up part run, otherwise it will only run to gather data

.PARAMETER noprompt
If the cleanup flag is set this will not prompt if you are sure you want to run the delete command

.PARAMETER help
Runs Get-Help -Full for the script

.EXAMPLE
# Linux tmp location
# This just will run again all known subscriptions and save the data to the artifact save path.
PS> .\main.ps1 -artifactSavePath /tmp/rbac/
.EXAMPLE
# Windows User Location
# This just will run again all known subscriptions and save the data to the artifact save path.
PS> .\main.ps1 -artifactSavePath $(Join-Path -Path ([System.IO.Path]::GetTempPath())) -ChildPath "rbac"
.EXAMPLE
# This will run against all known subscriptiosn and remove identities
PS> .\main.ps1 -cleanup -artifactSavePath $(Join-Path -Path ([System.IO.Path]::GetTempPath())) -ChildPath "rbac"
.EXAMPLE
# This will run against the 3 listed subscriptions and remove identities
PS> .\main.ps1 -cleanup -noprompt -subscriptionIdsStr "subid_1,subid_2,subid_3" -artifactSavePath $(Join-Path -Path ([System.IO.Path]::GetTempPath())) -ChildPath "rbac"
.EXAMPLE
# This will run against the 1 listed subscriptions and NOT remove identities
PS> .\main.ps1 -subscriptionIdsStr "subid_1" -artifactSavePath $(Join-Path -Path ([System.IO.Path]::GetTempPath())) -ChildPath "rbac"

.EXAMPLE
# This will run against all known subscriptiosn except the 1
PS> .\main.ps1 -excludeSubscriptionIdsStr "subid_1" -artifactSavePath $(Join-Path -Path ([System.IO.Path]::GetTempPath())) -ChildPath "rbac"

#> 

param(
  [string]$artifactSavePath,

  [string]$subscriptionIdsStr = $null,
  [string]$excludeSubscriptionIdsStr = $null,
  
  [switch] $verbose,
  [switch] $cleanup,
  [switch] $noprompt,
  [switch] $help

)
# $verbose =  (!!(Write-Verbose "" 4>&1))

# this was added because it was not working in my pwsh 7.4 testing on ubuntu
if($verbose){
  $VerbosePreference = "Continue"
}

if ($help -eq $true -or [string]::IsNullOrWhiteSpace($artifactSavePath))
{
    Get-Help $MyInvocation.MyCommand.Path -Full
    return
}


if ($cleanup -eq $true -and (-not $noprompt))
{
  $approvePrompt = Read-Host "Do you want to make updates to the subscription? Please enter Yes/Y"
  if($approvePrompt -ieq "yes" -or $approvePrompt -ieq "y"){
    $approvePrompt = "true"
  }
  if(-not [boolean]::TryParse($approvePrompt, [ref]$cleanup)){
    $cleanup = $False
  }
}

$script_directory = $MyInvocation.MyCommand.Path | Split-Path -Parent
$main_assets_directory = $(Resolve-Path -Path $(Join-Path -Path $script_directory -ChildPath "../assets")).Path
$cleanAzurePSCreds = $false
Clear-AzContext -Force

. "$($main_assets_directory)/helpers/general.ps1"


# $requiredCLIVeresion = ([System.Version]"2.48.1")
# Update-AzureCLI -requiredCLIVeresion $requiredCLIVeresion

$artifactSavePathDirectory = [System.IO.DirectoryInfo]$artifactSavePath
if(-not $artifactSavePathDirectory.Exists){
  $artifactSavePathDirectory.Create()
}
$unknownIdentityArtifactsDirectory = $artifactSavePathDirectory.CreateSubdirectory("unknownIdentity")


# Null-coalescing added in 7
# https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_operators?view=powershell-7.3#null-coalescing-operator-
if ($PSVersionTable.PSVersion.Major -le 6){
  throw "This script requires Powershell Core >=7 )" 
  exit
}

function Get-IsAssignmentScopeAtManagementGroup{
  param(
    [PSCustomObject]$assignment
  )

  return ($assignment.scope.toLower().startsWith("/providers/Microsoft.Management/managementGroups/".toLower()))
}

function Get-IsAssignmentScopeAtSubscriptionLevel{
  param(
    [PSCustomObject]$assignment,
    [string]$subscriptionId
  )

  return ($assignment.scope -ieq "/subscriptions/$($subscriptionId)")
}

function Get-IsAssignmentScopeInSubscription{
  param(
    [PSCustomObject]$assignment,
    [string]$subscriptionId
  )

  return ((Get-IsAssignmentScopeAtSubscriptionLevel -assignment $assignment -subscriptionId $subscriptionId) -or $assignment.scope.toLower().startsWith("/subscriptions/$($subscriptionId)/".toLower()))
}

function Convert-PSRoleAssignmentCLI{
  param(
    [PSCustomObject[]]$assignment_roles
  )

  $return_data = New-Object System.Collections.Generic.List[hashtable]
  foreach($assignment in $assignment_roles){
    $return_data.add(@{
      id = $assignment.RoleAssignmentId
      name = $assignment.RoleAssignmentName
      principalId = $assignment.ObjectId
      principalName = $([string]::IsNullOrWhiteSpace($assignment.DisplayName) -and [string]::IsNullOrWhiteSpace($assignment.SignInName)? "" : "$($assignment.DisplayName)-$($assignment.SignInName)")
      principalType = $assignment.ObjectType
      roleDefinitionId = $assignment.RoleDefinitionId
      roleDefinitionName = $assignment.RoleDefinitionName
      scope = $assignment.Scope
    })
  }
  return $return_data
}

function Set-PSSetContext{
  param(
    [string]$subscriptionId
  )

  Write-Verbose "Ensuring Azure PowerShell Configured"
  
  ($context = Get-AzContext )>$null
  if (!$context) 
  {    
    Connect-AZPowerShellCLI -userId $userId -subscriptionId $subscriptionId
    $context = Get-AzContext
  }

  if($context.Subscription.Id -ine $subscriptionId){
    try{
      Set-AzurePSContext -subscriptionId $subscriptionId
    }
    catch{
      Connect-AZPowerShellCLI -userId $userId -subscriptionId $subscriptionId
    }
  }

}

function Get-PSRoleAssignment{
  param(
    [string]$subscriptionId
  )
  

  $subscription_role_assignments = (Convert-PSRoleAssignmentCLI $(Get-AzRoleAssignment -Scope "/subscriptions/$($subscriptionId)" | ` 
    Where-Object {$_.Scope -ieq "/subscriptions/$($subscriptionId)"}))

  return $subscription_role_assignments
  

}

function Get-SubscriptionRoleAssignmentsUnknown {
  param(
    [Parameter(Mandatory=$true)]
    [string]$subscriptionId,
    [Parameter(Mandatory=$true)]
    $subscription_role_assignments
  )

  $subscription_role_assignments_unknown = $($subscription_role_assignments | Where-Object {[string]::IsNullOrWhiteSpace($_.principalName)})
  $subscription_role_assignments_unknown_mg = $($subscription_role_assignments_unknown | Where-Object { (Get-IsAssignmentScopeAtManagementGroup -assignment $_ ) })
  $subscription_role_assignments_unknown_outside = $($subscription_role_assignments_unknown | Where-Object { (-not (Get-IsAssignmentScopeAtManagementGroup -assignment $_ )) -and (Get-IsAssignmentScopeInSubscription -assignment $_ -subscriptionId $subscriptionId) })

  $subscription_role_assignments_count = $(($subscription_role_assignments | Measure-Object).Count)
  $subscription_role_assignments_unknown_count = $(($subscription_role_assignments_unknown | Measure-Object).Count)
  $subscription_role_assignments_unknown_mg_count = $(($subscription_role_assignments_unknown_mg | Measure-Object).Count)
  $subscription_role_assignments_unknown_outside_count = $(($subscription_role_assignments_unknown_outside | Measure-Object).Count)
  Debug-LogMessage -LogLevel 'Host' -LogMessage "Total Role Assignments: $($subscription_role_assignments_count)"
  Debug-LogMessage -LogLevel 'Host' -LogMessage "Total Unknown Role Assignments: $($subscription_role_assignments_unknown_count)"
  Debug-LogMessage -LogLevel 'Host' -LogMessage "Total Unknown Role Assignments at Management Group: $($subscription_role_assignments_unknown_mg_count)"
  Debug-LogMessage -LogLevel 'Host' -LogMessage "Total Unknown Role Assignments outside Subscription (non MG): $($subscription_role_assignments_unknown_outside_count)"

  return @{
    unknown = $subscription_role_assignments_unknown
    assignments_count = $subscription_role_assignments_count
    unknown_count = $subscription_role_assignments_unknown_count
  }

}

function Get-SubscriptionRoleAssignments {
  param(
    [Parameter(Mandatory=$true)]
    [string]$subscriptionId

  )
  $hasError = $false
  $subscription_role_assignments = $(az role assignment list --all --subscription "$($subscription.id)" | ConvertFrom-Json -Depth 20) 
  if ($null -eq $subscription_role_assignments){
    return @{
      role_assignments = @()
      role_assignments_unknown = @()
      hasError = $true
    }
  }
  $subscription_role_assignments_details = $(Get-SubscriptionRoleAssignmentsUnknown -subscriptionId $subscriptionId -subscription_role_assignments $subscription_role_assignments )


  if($subscription_role_assignments_details.assignments_count -eq $subscription_role_assignments_details.unknown_count){
    Debug-LogMessage -LogLevel 'Warning' -LogMessage "Appears to be an issue with the CLI pulling data probably missing attribute principalName"    
    Set-PSSetContext -subscriptionId $subscriptionId >$null
    $subscription_role_assignments = (Get-PSRoleAssignment -subscriptionId $subscriptionId)
    $subscription_role_assignments_details = $(Get-SubscriptionRoleAssignmentsUnknown -subscriptionId $subscriptionId -subscription_role_assignments $subscription_role_assignments )
    
    if($subscription_role_assignments_details.assignments_count -eq $subscription_role_assignments_details.unknown_count){
      Debug-LogMessage -LogLevel 'Error' -LogMessage "Total Role Assignments and Unknown role assignments appear to be the same skipping"
      $subscription_role_assignments_details.unknown = @()
      $hasError = $true
    }
  }
  
  return @{
    role_assignments = $subscription_role_assignments
    role_assignments_unknown = $subscription_role_assignments_details.unknown
    hasError = $hasError
  }

}


$subscriptions = (az account list | ConvertFrom-Json -Depth 10)

if($verbose){
  foreach($subscription in $subscriptions){
    Write-Verbose "Found Subscription $($subscription.id) ($($subscription.name))"
  }
}

if([string]::IsNullOrWhiteSpace($subscriptionIdsStr)){
  $subscriptionIds = $null
}
else{
  $subscriptionIds = @()
  $subscriptionIdsStr.ToLower().Split(",") | ForEach-Object {
    $subscriptionIds += @($_.Trim())
  }
}

Write-Verbose "Testing Subscription Ids: $($subscriptionIds)"

if([string]::IsNullOrWhiteSpace($excludeSubscriptionIdsStr)){
  $excludeSubscriptionIds = $null
}
else{
  $excludeSubscriptionIds = @()
  $excludeSubscriptionIdsStr.ToLower().Split(",") | ForEach-Object {
    $excludeSubscriptionIds += @($_.Trim())
  }
}
Write-Verbose "Exclude Subscription Ids: $($excludeSubscriptionIds)"

$unknownIdentityBySubscription = @{
}

$hasError = $false
foreach($subscription in $subscriptions){
  $subscriptionId = $subscription.id.ToLower()
  if(($null -ne $subscriptionIds) -and (-not ($subscriptionId -in $subscriptionIds))){
    Write-Verbose "Skipping subscription $($subscription.id) ($($subscription.name))"
    continue
  }
  if(($subscriptionId -in $excludeSubscriptionIds)){
    Write-Verbose "Exclude subscription $($subscription.id) ($($subscription.name))"
    continue
  }

  Write-host ""
  Write-host "-----------------------"
  Write-host ""
  Debug-LogMessage -LogLevel 'Host' -LogMessage "Processing Subscription $($subscription.id) ($($subscription.name))"
  
  $unknownIdentityBySubscription[$subscriptionId] = @{
    id = $subscriptionId
    name = $subscription.name
    data=@{}
  }

  
  $role_assignments = Get-SubscriptionRoleAssignments -subscriptionId "$($subscription.id)"
  if($role_assignments.hasError){
    Debug-LogMessage -LogLevel 'Host' -LogMessage "Subscription has error skipping"
    $hasError = $true
    continue
  }
  
  $cleanup_array =New-Object System.Collections.Generic.List[string]
  $cleanup_count = 0
  
  foreach($assignment in $role_assignments.role_assignments_unknown){
    if($cleanup_array.Count -lt 1){
      $cleanup_array.Add("--ids")
    }
    if($null -eq $unknownIdentityBySubscription[$subscriptionId].data[$assignment.scope.ToLower()]){
      $unknownIdentityBySubscription[$subscriptionId].data[$assignment.scope.ToLower()] = New-Object System.Collections.Generic.List[hashtable]
    }
    
    $unknownIdentityBySubscription[$subscriptionId].data[$assignment.scope.ToLower()].Add(@{
      id = $assignment.id
      name = $assignment.name
      principalId = $assignment.principalId
      principalName = $assignment.principalName
      principalType = $assignment.principalType
      roleDefinitionId = $assignment.roleDefinitionId
      roleDefinitionName = $assignment.roleDefinitionName
      scope = $assignment.scope
    })
    
    if(-not (Get-IsAssignmentScopeInSubscription -assignment $assignment -subscriptionId $subscriptionId)){
      write-verbose "Skipping Assignment Scope outside of subscription - $($assignment.name) - $($assignment.scope)"
      continue
    }

    $cleanup_array.add($assignment.id)
    
    if($cleanup_array.Count -gt 10 -and $cleanup){
      write-verbose "Running Cleanup - $($subscription.id) - $($cleanup_array | ConvertTo-Json)"
      az role assignment delete --subscription "$($subscription.id)" $cleanup_array
      $cleanup_count += $cleanup_array.Count
      $cleanup_array.clear()
    }
    
  }

  if($cleanup_array.Count -gt 1 -and $cleanup){
    $cleanup_count += $cleanup_array.Count
    az role assignment delete --subscription "$($subscription.id)" $cleanup_array
    $cleanup_array.clear()
  }

  Debug-LogMessage -LogLevel 'Host' -LogMessage "Total Role Assignments Deleted: $($cleanup_count)"
  Debug-LogMessage -LogLevel 'Host' -LogMessage "Processing Subscription $($subscription.id) / $($subscription.name) - Finished"
  Write-host ""
  Write-host "-----------------------"
  Write-host ""
}

$artifactSaveFilePath = $(Join-Path -Path $unknownIdentityArtifactsDirectory.FullName -ChildPath "unknownIdentities.json" )
Write-Host "The results have been saved to: $($artifactSaveFilePath)"
Save-ArtifactData -data $unknownIdentityBySubscription -savePath (Join-Path -Path $unknownIdentityArtifactsDirectory.FullName -ChildPath "unknownIdentities.json" )

if($cleanAzurePSCreds){
  Disconnect-AzAccount 
  Clear-AzContext -Force
}

if($hasError ){
  throw "Error processing one or more subscription"
}