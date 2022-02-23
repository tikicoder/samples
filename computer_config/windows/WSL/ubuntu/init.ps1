$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "general\defaults.ps1")"



wsl mkdir -p $tmp_setup_path

if (Test-Path "\\wsl$\Ubuntu\etc\wsl.conf"){Remove-Item -Path "\\wsl$\Ubuntu\etc\wsl.conf"}
Copy-item -Path $(Join-Path -Path $scriptPath_init -ChildPath "..\config\wsl.conf") -Destination "\\wsl$\Ubuntu\etc\wsl.conf"

# disable sudo password for default user
if (Test-Path "\\wsl$\Ubuntu\$tmp_setup_path\disable_sudo_pass.sh"){Remove-Item -Path "\\wsl$\Ubuntu\$tmp_setup_path\disable_sudo_pass.sh"}
Copy-item -Path $(Join-Path -Path $scriptPath_init -ChildPath "..\general\disable_sudo_pass.sh") -Destination "\\wsl$\Ubuntu\$tmp_setup_path\disable_sudo_pass.sh"

wsl bash $tmp_setup_path/disable_sudo_pass.sh

wsl sudo apt update 
wsl sudo apt upgrade -y

$files_copy = Get-ChildItem "$($scriptPath_init)/run_files/*.ps1" -File | Sort-Object -Property Name
foreach ( $file in $missing_root_certs){
  & $file.FullName 
}



& "$(Join-Path -Path $scriptPath_init -ChildPath "..\..\..\..\general_programming_scripting\powershell\vsCode\vsCodeManuallBackup.ps1" | Resolve-Path)" -isRestore $true -wsl_command Ubuntu

wsl rm -Rf $tmp_setup_path
wsl rm /etc/sudoers.d/``whoami``