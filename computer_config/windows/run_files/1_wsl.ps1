$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"


if(-not $is_admin_context ){
  Write-Host "running as Admin"
  start-process -verb runas -ArgumentList "-Command $($scriptPath_init)\$($MyInvocation.MyCommand.Name)" pwsh
  exit
}
Write-Host "Please install WSL from the MS Store"
Write-Host "https://aka.ms/wslstorepage"
pause 

wsl --update
$wsl_current_version = $(Get-ItemPropertyValue `
      -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Lxss `
      -Name DefaultVersion)
if(-not $?){
  $wsl_current_version = 1
}
if($wsl_current_version -lt 2){
  wsl --set-default-version 2
}


# https://docs.microsoft.com/en-us/windows/wsl/wsl-config
# Configures mem limit on WSL Config
if (Test-Path -Path "$HOME\.wslconfig") {Remove-Item -Force -Path "$HOME\.wslconfig"}
Copy-Item -Path $(Join-Path -Path $scriptPath_init -ChildPath "..\general\wsl\config\.wslconfig") -Destination "$HOME\.wslconfig"



