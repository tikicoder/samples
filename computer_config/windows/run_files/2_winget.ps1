$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

write-host "7zip installing"
winget install -e --id 7zip.7zip


write-host "Wireshark installing"
winget install -e --id WiresharkFoundation.Wireshark

write-host "PuTTY installing"
winget install -e --id PuTTY.PuTTY

write-host "VisualStudioCode installing"
winget install -e --id Microsoft.VisualStudioCode
& "$(Join-Path -Path $scriptPath_init -ChildPath "..\..\..\general_programming_scripting\powershell\vsCode\vsCodeManuallBackup.ps1")" -isRestore $true -skip_wsl $true 

write-host "PowerShell installing"
winget install -e --id Microsoft.PowerShell

write-host "AzureStorageExplorer installing"
winget install -e --id Microsoft.AzureStorageExplorer

write-host "MS Edge installing"
winget install -e --id Microsoft.Edge

write-host "WindowsTerminal installing"
winget install -e --id Microsoft.WindowsTerminal

write-host "IrfanView installing"
winget install -e --id IrfanSkiljan.IrfanView

write-host "Atom installing"
winget install -e --id GitHub.Atom

write-host "GIMP installing"
winget install -e --id GIMP.GIMP

write-host "OBSStudio installing"
winget install -e --id OBSProject.OBSStudio

write-host "Chrome installing"
winget install -e --id Google.Chrome

write-host "Slack installing"
winget install -e --id SlackTechnologies.Slack
