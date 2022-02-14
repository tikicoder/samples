
write-host "WSL configure"
# https://docs.microsoft.com/en-us/windows/wsl/install-manual
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart


write-host "Before finishing WSL configure"
Write-host "A Browser will now open please check the WSL steps to see what needs to happen before the install"
pause
Start-Process "https://docs.microsoft.com/en-us/windows/wsl/install-manual"