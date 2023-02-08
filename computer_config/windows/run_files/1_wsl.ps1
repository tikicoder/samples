$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

Write-Host "Please install WSL from the MS Store"
Write-Host "https://aka.ms/wslstorepage"
pause 

wsl --upgrade
wsl --set-default-version 2


# https://docs.microsoft.com/en-us/windows/wsl/wsl-config
# Configures mem limit on WSL Config
if (Test-Path -Path "$HOME\.wslconfig") {Remove-Item -Force -Path "$HOME\.wslconfig"}
Copy-Item -Path $(Join-Path -Path $scriptPath_init -ChildPath "..\general\wsl\config\.wslconfig") -Destination "$HOME\.wslconfig"



