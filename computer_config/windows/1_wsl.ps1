$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition


wsl --set-default-version 2

# https://docs.microsoft.com/en-us/windows/wsl/wsl-config
# Configures mem limit on WSL Config
"[wsl2]" >> "$HOME/.wslconfig"
"memory=2GB" >> "$HOME/.wslconfig"
"swap=512MB" >> "$HOME/.wslconfig"

