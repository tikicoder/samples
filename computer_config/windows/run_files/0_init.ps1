$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"


if(-not $is_admin_context ){
  Write-Host "running as Admin"
  start-process -verb runas -ArgumentList "-Command $($scriptPath_init)\$($MyInvocation.MyCommand.Name)" pwsh
  exit
}

function Update-FolderView() {

  $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
  Set-ItemProperty -Path $Path -Name "Hidden" -Value 1  
  Set-ItemProperty -Path $Path -Name "HideFileExt" -Value 0

}

write-host "Set folder view settings"
Update-FolderView

write-host "Enable Hyper-V"
DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V /norestart

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

Write-Host "Get Latest versions of Visual C++ Distro"
Write-Host "https://learn.microsoft.com/en-US/cpp/windows/latest-supported-vc-redist?view=msvc-170"
pause

Write-Host "\n\n"

Write-Host "Please install App Installer (winget)"
Write-Host "https://apps.microsoft.com/store/detail/app-installer/9NBLGGH4NNS1?hl=en-us&gl=us&rtc=1"
Write-Host "GitHub"
Write-Host "https://github.com/microsoft/winget-cli"
pause

Write-Host "Running winget search dotnet to ensure nothing needs to be configured"
winget search --id Microsoft.dotnet

Write-Host "Please install PowerShell Core"
Write-Host "https://github.com/PowerShell/PowerShell"
pause

