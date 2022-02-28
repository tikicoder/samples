$scriptPath_init_general = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init_general -ChildPath "..\..\..\general\defaults.ps1")"

$general_defaults.main_distro = "Ubuntu"