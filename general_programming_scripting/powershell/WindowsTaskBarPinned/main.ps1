$scriptPath = split-path -parent $MyInvocation.MyCommand.Definition

$user_taskbar_pined_shortcuts_path = "$($env:APPDATA)\Microsoft\Internet Explorer\Quick Launch\User Pinned\TaskBar"

Compress-Archive -Path $user_taskbar_pined_shortcuts_path -DestinationPath $(Join-Path "$scriptPath" "TaskBar.zip")

reg export "HKEY_CURRENT_USER\Software\Microsoft\Windows\CurrentVersion\Explorer\Taskband" $(Join-Path "$scriptPath" "Taskband.reg")