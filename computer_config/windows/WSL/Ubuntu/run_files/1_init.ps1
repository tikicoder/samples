$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

if (Test-Path "\\wsl$\Ubuntu$($general_defaults.tmp_directory)\wsl.conf"){Remove-Item -Path "\\wsl$\Ubuntu$($general_defaults.tmp_directory)\wsl.conf"}
Copy-item -Path $(Join-Path -Path $scriptPath_init -ChildPath "..\..\general\wsl\config\wsl.conf") -Destination "\\wsl$\Ubuntu$($general_defaults.tmp_directory)\wsl.conf"

if (Test-Path "\\wsl$\Ubuntu$($general_defaults.tmp_directory)\1_init.sh"){Remove-Item -Path "\\wsl$\Ubuntu$($general_defaults.tmp_directory)\1_init.sh"}
Copy-item -Force -Path $(Join-Path -Path $scriptPath_init -ChildPath "1_init.sh" ) -Destination "\\wsl$\Ubuntu$($general_defaults.tmp_directory)\1_init.sh)"


wsl -d Ubuntu bash "$($general_defaults.tmp_directory)/1_init.sh" "$($general_defaults.tmp_directory)"
wsl -d Ubuntu rm "$($general_defaults.tmp_directory)/1_init.sh"
