$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"




wsl -d $general_defaults.main_distro az config set auto-upgrade.enable=yes
wsl -d $general_defaults.main_distro az config set extension.use_dynamic_install=yes_prompt

