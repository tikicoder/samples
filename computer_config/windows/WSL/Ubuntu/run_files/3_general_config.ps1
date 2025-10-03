$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\..\..\general\wsl\runscript_default.ps1")"



