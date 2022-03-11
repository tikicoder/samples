$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

write-host "Enable IIS"
dism /online /enable-feature /all `
  /featurename:WCF-Services45 `
  /featurename:WCF-TCP-PortSharing45 `
  /featurename:IIS-WebServerRole `
  /featurename:IIS-WebServer `
  /featurename:IIS-CommonHttpFeatures `
  /featurename:IIS-HttpErrors `
  /featurename:IIS-HttpRedirect `
  /featurename:IIS-ApplicationDevelopment `
  /featurename:IIS-HealthAndDiagnostics `
  /featurename:IIS-HttpLogging `
  /featurename:IIS-Security `
  /featurename:IIS-RequestFiltering `
  /featurename:IIS-URLAuthorization `
  /featurename:IIS-Performance `
  /featurename:IIS-HttpCompressionDynamic `
  /featurename:IIS-WebServerManagementTools `
  /featurename:IIS-IIS6ManagementCompatibility `
  /featurename:IIS-Metabase `
  /featurename:IIS-StaticContent `
  /featurename:IIS-DefaultDocument `
  /featurename:IIS-DirectoryBrowsing `
  /featurename:IIS-WebSockets `
  /featurename:IIS-ASPNET `
  /featurename:IIS-ASPNET45 `
  /featurename:IIS-HttpCompressionStatic `
  /featurename:IIS-ManagementConsole

write-host "Enable Hyper-V"
# Needed for Docker
DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V /norestart

write-host "WSL configure"
# https://docs.microsoft.com/en-us/windows/wsl/install-manual
dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart


write-host "Before finishing WSL configure"
Write-host "A Browser will now open please check the WSL steps to see what needs to happen before the install"
pause
Start-Process "https://docs.microsoft.com/en-us/windows/wsl/install-manual"

Write-host "Before Continuing please finish steps from browser"
pause
