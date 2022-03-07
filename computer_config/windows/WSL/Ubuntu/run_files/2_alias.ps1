$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"


if (Test-Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\2_alias.sh"){Remove-Item -Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\2_alias.sh"}
Copy-item -Force -Path $(Join-Path -Path $scriptPath_init -ChildPath "2_alias.sh" ) -Destination "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\2_alias.sh"


wsl -d $general_defaults.main_distro bash "'$($general_defaults.tmp_directory)/2_alias.sh'" "'$($general_defaults.tmp_directory)'"
wsl -d $general_defaults.main_distro rm "$($general_defaults.tmp_directory)/2_alias.sh"
