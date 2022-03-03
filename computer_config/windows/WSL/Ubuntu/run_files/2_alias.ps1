$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"


if (Test-Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\1_init.sh"){Remove-Item -Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\1_init.sh"}
Copy-item -Force -Path $(Join-Path -Path $scriptPath_init -ChildPath "1_init.sh" ) -Destination "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\1_init.sh"


wsl -d $general_defaults.main_distro bash "'$($general_defaults.tmp_directory)/1_init.sh'" "'$($general_defaults.tmp_directory)'"
wsl -d $general_defaults.main_distro rm "$($general_defaults.tmp_directory)/1_init.sh"
