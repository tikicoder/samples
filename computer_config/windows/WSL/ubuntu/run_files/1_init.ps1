$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"


Copy-item -Path $(Join-Path -Path $scriptPath_init -ChildPath "1_init.sh" ) -Destination "\\wsl$\Ubuntu\$tmp_setup_path\1_init.sh)"


wsl -d Ubuntu bash $tmp_setup_path/1_init.sh
wsl -d Ubuntu rm $tmp_setup_path/1_init.sh
