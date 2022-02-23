$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"


Copy-item -Path $(Join-Path -Path $scriptPath_init -ChildPath "1_init.sh" ) -Destination "\\wsl$\Ubuntu\$($general_defaults.tmp_directory)\1_init.sh)"


wsl -d Ubuntu bash $general_defaults.tmp_directory/1_init.sh
wsl -d Ubuntu rm $general_defaults.tmp_directory/1_init.sh
