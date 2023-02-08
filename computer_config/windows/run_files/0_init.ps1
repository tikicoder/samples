$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

function Update-FolderView() {

  $Path = "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
  Set-ItemProperty -Path $Path -Name "Hidden" -Value 1  
  Set-ItemProperty -Path $Path -Name "HideFileExt" -Value 0

}

function Install-WSL()
{
  
  param (
    [bool]$auto_install = $false
  )
  if ( (Get-CimInstance Win32_OperatingSystem).BuildNumber -ge 19041 -and $auto_install){
    # If this is ran it will install a default distro and I Do not want that
    wsl --install
    return
  }


  write-host "Enable Hyper-V"
  # Needed for Docker
  DISM /Online /Enable-Feature /All /FeatureName:Microsoft-Hyper-V /norestart

  write-host "WSL configure"
  # https://docs.microsoft.com/en-us/windows/wsl/install-manual
  dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart

  dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart

  # I do not think this is needed with wsl --upgrade
  # write-host "Before finishing WSL configure"
  # Write-host "A Browser will now open please check the WSL steps to see what needs to happen before the install"
  # pause
  # Start-Process "https://docs.microsoft.com/en-us/windows/wsl/install-manual"

  # Write-host "Before Continuing please finish steps from browser"
  # pause
}

write-host "Set folder view settings"
Update-FolderView

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

Write-Host "Please install PowerShell Core"
Write-Host "https://github.com/PowerShell/PowerShell"
pause

Install-WSL 
