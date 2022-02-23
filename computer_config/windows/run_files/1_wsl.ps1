$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition


wsl --set-default-version 2

# https://docs.microsoft.com/en-us/windows/wsl/wsl-config
# Configures mem limit on WSL Config
if (Test-Path -Path "$HOME\.wslconfig") {Remove-Item -Force -Path "$HOME\.wslconfig"}
Copy-Item -Path $(Join-Path -Path $scriptPath_init -ChildPath "WSL\config\.wslconfig") -Destination "$HOME\.wslconfig"



