$scriptPath_init_mainset = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init_mainset -ChildPath "general\defaults.ps1")"

if ($(wsl -l | Where-Object {$_ -ieq $($general_defaults.main_distro) -or $_ -ieq "$($general_defaults.main_distro) (Default)"} | Measure-Object).Count -lt 1){
  write-host "$($general_defaults.main_distro) installing via winget"
  winget install -e --id Canonical.$($general_defaults.main_distro)
  write-host "Opening $($general_defaults.main_distro) to Configure Once configured please type exit to go back to PowerShell"
  wsl -d $($general_defaults.main_distro)
  wsl --setdefault $($general_defaults.main_distro)
  wsl -d $($general_defaults.main_distro) sudo apt update 
  wsl -d $($general_defaults.main_distro) sudo apt upgrade -y
}


wsl -d $($general_defaults.main_distro) mkdir -p $general_defaults.tmp_directory

# disable sudo password for default user
if (Test-Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"){Remove-Item -Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"}
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\disable_sudo_pass.sh") -Destination "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"

wsl -d $($general_defaults.main_distro) bash "$($general_defaults.tmp_directory)/disable_sudo_pass.sh"

wsl -d $($general_defaults.main_distro) sudo apt list --upgradable

$files_copy = $(Get-ChildItem "$($scriptPath_init_mainset)/run_files/*.ps1" -File | Sort-Object -Property Name)
foreach ( $file in $files_copy){
  Write-Host "Running $($file.Name)"
  & $file.FullName 
}

Write-Host "Running VS Code restore"
& "$(Join-Path -Path $scriptPath_init_mainset -ChildPath "..\..\..\..\general_programming_scripting\powershell\vsCode\vsCodeManuallBackup.ps1" | Resolve-Path)" -isRestore $true -wsl_command $($general_defaults.main_distro)

if (Test-Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\user_docker_init.sh"){Remove-Item -Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\user_docker_init.sh"}
Write-Host "Coping Script user_docker_init.sh"
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\user_docker_init.sh") -Destination "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\user_docker_init.sh"
wsl -d $($general_defaults.main_distro) bash "$($general_defaults.tmp_directory)/user_docker_init.sh" "'$($general_defaults.docker_sock)'" "'$($general_defaults.docker_host_sock)'" "'$($general_defaults.docker_distro)'" "'$($general_defaults.docker_dir)'"



wsl -d $($general_defaults.main_distro) rm -Rf $($general_defaults.tmp_directory)
wsl -d $($general_defaults.main_distro) sudo rm /etc/sudoers.d/``whoami``