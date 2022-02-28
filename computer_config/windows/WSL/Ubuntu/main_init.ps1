$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "general\defaults.ps1")"

if ($(wsl -l | Where-Object {$_ -ieq 'Ubuntu' -or $_ -ieq 'Ubuntu (Default)'} | Measure-Object).Count -lt 1){
  write-host "Ubuntu installing via winget"
  winget install -e --id Canonical.Ubuntu
  write-host "Opening Ubuntu to Configure Once configured please type exit to go back to PowerShell"
  wsl -d Ubuntu
  wsl --setdefault Ubuntu
  wsl -d Ubuntu sudo apt update 
  wsl -d Ubuntu sudo apt upgrade -y
}


wsl -d Ubuntu mkdir -p $general_defaults.tmp_directory

# disable sudo password for default user
if (Test-Path "\\wsl$\Ubuntu$($general_defaults.tmp_directory)\disable_sudo_pass.sh"){Remove-Item -Path "\\wsl$\Ubuntu$($general_defaults.tmp_directory)\disable_sudo_pass.sh"}
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\disable_sudo_pass.sh") -Destination "\\wsl$\Ubuntu$($general_defaults.tmp_directory)\disable_sudo_pass.sh"

wsl -d Ubuntu bash "$($general_defaults.tmp_directory)/disable_sudo_pass.sh"

wsl -d Ubuntu sudo apt list --upgradable

$files_copy = $(Get-ChildItem "$($scriptPath_init)/run_files/*.ps1" -File | Sort-Object -Property Name)
foreach ( $file in $missing_root_certs){
  Write-Host "Running $($file.Name)"
  & $file.FullName 
}

& "$(Join-Path -Path $scriptPath_init -ChildPath "..\..\..\..\general_programming_scripting\powershell\vsCode\vsCodeManuallBackup.ps1" | Resolve-Path)" -isRestore $true -wsl_command Ubuntu

if (Test-Path "\\wsl$\Ubuntu$($general_defaults.tmp_directory)\user_docker_init.sh"){Remove-Item -Path "\\wsl$\Ubuntu$($general_defaults.tmp_directory)\user_docker_init.sh"}
Write-Host "Coping Script disable_sudo_pass.sh"
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\user_docker_init.sh") -Destination "\\wsl$\Ubuntu$($general_defaults.tmp_directory)\user_docker_init.sh"
wsl -d Ubuntu bash "$($general_defaults.tmp_directory)/user_docker_init.sh" "$($general_defaults.docker_sock)" "$($general_defaults.docker_host_sock)" "$($general_defaults.tiki_docker_desktop)" "$($general_defaults.docker_dir)"


$general_defaults.repo_root
wsl -d Ubuntu rm -Rf $($general_defaults.tmp_directory)
wsl -d Ubuntu sudo rm /etc/sudoers.d/``whoami``