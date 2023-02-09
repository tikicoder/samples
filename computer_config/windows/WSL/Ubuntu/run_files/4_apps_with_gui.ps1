$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

$app_name = "4_apps_with_gui"

if (Test-Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\$($app_name).sh"){Remove-Item -Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\$($app_name).sh"}
Copy-item -Force -Path $(Join-Path -Path $scriptPath_init -ChildPath "$($app_name).sh" ) -Destination "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\$($app_name).sh"


wsl -d $general_defaults.main_distro bash "'$($general_defaults.tmp_directory)/$($app_name).sh'" "'$($general_defaults.tmp_directory)'"
wsl -d $general_defaults.main_distro rm "$($general_defaults.tmp_directory)/$($app_name).sh"
