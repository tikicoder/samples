$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "general\defaults.ps1")"

if ($(wsl -l | Where-Object {$_ -ieq 'Ubuntu'} | Measure-Object).Count -lt 1){
  write-host "Ubuntu installing"
  winget install -e --id Canonical.Ubuntu
  wsl -d Ubuntu
  wsl --setdefault Ubuntu
  wsl -d Ubuntu sudo apt update 
  wsl -d Ubuntu sudo apt upgrade -y
}


wsl -d Ubuntu mkdir -p $general_defaults.tmp_directory

if (Test-Path "\\wsl$\Ubuntu\etc\wsl.conf"){Remove-Item -Path "\\wsl$\Ubuntu\etc\wsl.conf"}
Copy-item -Path $(Join-Path -Path $scriptPath_init -ChildPath "..\..\general\wsl\config\wsl.conf") -Destination "\\wsl$\Ubuntu\etc\wsl.conf"

# disable sudo password for default user
if (Test-Path "\\wsl$\Ubuntu\$($general_defaults.tmp_directory)\disable_sudo_pass.sh"){Remove-Item -Path "\\wsl$\Ubuntu\$($general_defaults.tmp_directory)\disable_sudo_pass.sh"}
Copy-item -Path $(Join-Path -Path $scriptPath_init -ChildPath "..\..\general\\wsl\disable_sudo_pass.sh") -Destination "\\wsl$\Ubuntu\$($general_defaults.tmp_directory)\disable_sudo_pass.sh"

wsl -d Ubuntu bash $($general_defaults.tmp_directory)/disable_sudo_pass.sh


$files_copy = $(Get-ChildItem "$($scriptPath_init)/run_files/*.ps1" -File | Sort-Object -Property Name)
foreach ( $file in $missing_root_certs){
  Write-Host "Running $($file.Name)"
  & $file.FullName 
}

& "$(Join-Path -Path $scriptPath_init -ChildPath "..\..\..\..\general_programming_scripting\powershell\vsCode\vsCodeManuallBackup.ps1" | Resolve-Path)" -isRestore $true -wsl_command Ubuntu

wsl -d Ubuntu rm -Rf $($general_defaults.tmp_directory)
wsl -d Ubuntu rm /etc/sudoers.d/``whoami``