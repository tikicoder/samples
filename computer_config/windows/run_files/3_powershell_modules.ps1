$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

Write-Host "Install AZ Module for PS Core"
# https://learn.microsoft.com/en-us/powershell/azure/install-az-ps?view=azps-9.4.0
pwsh -Command Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force

Write-Host "Install AZ Module for Powershell"
Write-Host "Requires PowerShell 5.1 and .NET Framework 4.7.2 or later"
Write-Host "Please verify and then continue"
powershell -Command Write-Host `$PSVersionTable.PSVersion
Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP' -Recurse | Get-ItemProperty -Name version -EA 0 | Where { $_.PSChildName -Match '^(?!S)\p{L}'} | Select PSChildName, version
pause


powershell -command Install-Module -Name PowerShellGet -Force


Write-Host "Install PSRule for validating Azure Bicep"
pwsh -Command Install-Module -Name PSRule -Scope CurrentUser -Repository PSGallery -Force
Find-Module -Repository PSGallery -Name 'PSRule.Rules.*' | ForEach-Object {
  pwsh -Command Install-Module -Name $_.Name -Scope CurrentUser -Repository PSGallery -Force
}