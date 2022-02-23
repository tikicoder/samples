$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

if (Test-Path "\\wsl$\Ubuntu\$tmp_setup_path\distrod_install.sh"){Remove-Item -Path "\\wsl$\Ubuntu\$tmp_setup_path\distrod_install.sh"}
Copy-item -Path $(Join-Path -Path $scriptPath_init -ChildPath "1_Distrod.sh") -Destination "\\wsl$\Ubuntu\$tmp_setup_path\distrod_install.sh"

if (Test-Path "\\wsl$\Ubuntu\$tmp_setup_path\distrod_install.sh"){Remove-Item -Path "\\wsl$\Ubuntu\$tmp_setup_path\distrod_update.sh"}
Copy-item -Path $(Join-Path -Path $scriptPath_init -ChildPath "1_Distrod_update.sh") -Destination "\\wsl$\Ubuntu\$tmp_setup_path\distrod_update.sh"

wsl bash $tmp_setup_path/distrod_install.sh

Remove-Item -Path "\\wsl$\Ubuntu\$tmp_setup_path\distrod_install.sh"

wsl --shutdown

wsl echo "test"