$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"


function install-app-winget(){
  param(
    [string]$app_name
  )

  write-host "Installing - $($app_name)"

  if([string]::IsNullOrWhiteSpace($($(winget upgrade -e --id $app_name).trim().tolower() -match "no installed package found"))) {
    write-host "$app_name already installed"
    return
  }

  write-host "$app_name Installing"
  winget install -e --id $app_name
}


install-app-winget -app_name "7zip.7zip"

install-app-winget -app_name "WiresharkFoundation.Wireshark"

install-app-winget -app_name "PuTTY.PuTTY"

install-app-winget -app_name "Microsoft.VisualStudioCode"
& "$(Join-Path -Path $root_path_samples -ChildPath "general_programming_scripting\powershell\vsCode\main.ps1")" -isRestore $true -skip_wsl $true 

install-app-winget -app_name "Microsoft.PowerShell"

install-app-winget -app_name "Microsoft.AzureStorageExplorer"

install-app-winget -app_name "Microsoft.Edge"

install-app-winget -app_name "Microsoft.WindowsTerminal"

install-app-winget -app_name "IrfanSkiljan.IrfanView"

install-app-winget -app_name "GitHub.Atom"

install-app-winget -app_name "GIMP.GIMP"

install-app-winget -app_name "OBSProject.OBSStudio"

install-app-winget -app_name "Google.Chrome"

install-app-winget -app_name "SlackTechnologies.Slack"
