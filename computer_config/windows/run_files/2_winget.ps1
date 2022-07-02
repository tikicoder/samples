$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"


function install-app-winget(){
  param(
    [string]$app_name
  )

  if([string]::IsNullOrWhiteSpace($($(winget upgrade -e --id $app_name).trim().tolower() -match "No installed package found2"))) {
    write-host "$app_name already installed"
    return
  }

  winget install -e --id $app_name
}

write-host "7zip installing"
install-app-winget -app_name "7zip.7zip"

write-host "Wireshark installing"
install-app-winget -app_name "WiresharkFoundation.Wireshark"

write-host "PuTTY installing"
install-app-winget -app_name "PuTTY.PuTTY"

write-host "VisualStudioCode installing"
install-app-winget -app_name "Microsoft.VisualStudioCode"
& "$(Join-Path -Path $root_path_samples -ChildPath "general_programming_scripting\powershell\vsCode\main.ps1")" -isRestore $true -skip_wsl $true 

write-host "PowerShell installing"
install-app-winget -app_name "Microsoft.PowerShell"

write-host "AzureStorageExplorer installing"
install-app-winget -app_name "Microsoft.AzureStorageExplorer"

write-host "MS Edge installing"
install-app-winget -app_name "Microsoft.Edge"

write-host "WindowsTerminal installing"
install-app-winget -app_name "Microsoft.WindowsTerminal"

write-host "IrfanView installing"
install-app-winget -app_name "IrfanSkiljan.IrfanView"

write-host "Atom installing"
install-app-winget -app_name "GitHub.Atom"

write-host "GIMP installing"
install-app-winget -app_name "GIMP.GIMP"

write-host "OBSStudio installing"
install-app-winget -app_name "OBSProject.OBSStudio"

write-host "Chrome installing"
install-app-winget -app_name "Google.Chrome"

write-host "Slack installing"
install-app-winget -app_name "SlackTechnologies.Slack"
