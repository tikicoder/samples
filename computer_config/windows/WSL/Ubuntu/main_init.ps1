$scriptPath_init_mainset = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init_mainset -ChildPath "general\defaults.ps1")"

if ($(wsl -l | Where-Object {$_ -ieq $($general_defaults.main_distro) -or $_ -ieq "$($general_defaults.main_distro) (Default)"} | Measure-Object).Count -lt 1){
    write-host "Opening $($general_defaults.main_distro) to Configure Once configured please type exit to go back to PowerShell"
  Start-Process "wsl.exe" -ArgumentList @("--install", "-d", $general_defaults.main_distro) -passthru -Wait
  
  write-host "Waiting for $($general_defaults.main_distro) to be configured"
  while(($(wsl -l | Where-Object {$_ -ieq $($general_defaults.main_distro) -or $_ -ieq "$($general_defaults.main_distro) (Default)"} | Measure-Object).Count -lt 1)){
    Start-Sleep -m 500
  }
  write-host "$($general_defaults.main_distro) installed"

  write-host "$($general_defaults.main_distro): Pending User Setup"
  while($(wsl -d $($general_defaults.main_distro) echo ``whoami``) -ieq "root"){
    Start-Sleep -m 500
  }
  wsl --setdefault $($general_defaults.main_distro)
}

Wait-Distro-Start -Distro $general_defaults.main_distro
wsl -d $($general_defaults.main_distro) mkdir -p $general_defaults.tmp_directory

$local_user = $(wsl -d Ubuntu echo ``whoami``)
$local_user_groupid = $(wsl -d Ubuntu echo ``id -u $local_user``)
$local_user_id = $(wsl -d Ubuntu echo ``getent group $local_user `| `cut `-d: `-f3``)

if (Test-Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"){Remove-Item -Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"}
if (Test-Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\base_init.sh"){Remove-Item -Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\base_init.sh"}

# disable sudo password for default user
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\disable_sudo_pass.sh") -Destination "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"

# base init
Copy-item -Path $(Join-Path -Path $scriptPath_init_mainset -ChildPath "base_init.sh") -Destination "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\base_init.sh"

wsl -d $general_defaults.main_distro -e bash "$($general_defaults.tmp_directory)/base_init.sh" "'$($general_defaults.tmp_directory)'"


if (Test-Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\user_docker_init.sh"){Remove-Item -Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\user_docker_init.sh"}
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\user_docker_init.sh") -Destination "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\user_docker_init.sh"


if (Test-Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\wsl.conf"){Remove-Item -Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\wsl.conf"}
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\config\wsl.conf") -Destination "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\wsl.conf"

wsl --terminate $($general_defaults.main_distro)
Wait-Distro-Start -Distro $general_defaults.main_distro

# General Run steps
$files_copy = $(Get-ChildItem "$($scriptPath_init_mainset)/run_files/*.ps1" -File | Sort-Object -Property Name)
foreach ( $file in $files_copy){
  Write-Host "Running $($file.Name)"
  & $file.FullName 
}

Write-Host "Running Script user_docker_init.sh"
wsl -d $($general_defaults.main_distro) bash "$($general_defaults.tmp_directory)/user_docker_init.sh" "'$($general_defaults.docker_sock)'" "'$($general_defaults.docker_host_sock)'" "'$($general_defaults.docker_distro)'" "'$($general_defaults.docker_dir)'" "$($general_defaults.docker_gropuid)"


Write-Host "Running VS Code restore"

#ensures wslvs code is initialized
$scriptBlock_wsl = [Scriptblock]::Create("wsl -d $($wsl_command) code")
Invoke-Command -ScriptBlock $scriptBlock_wsl

$vsbackup = $(Join-Path -Path $scriptPath_init_mainset -ChildPath "..\..\..\..\general_programming_scripting\powershell\vsCode\main.ps1" | Resolve-Path)
if ( Test-Path $vsbackup ){
  & $vsbackup -isRestore $true -wsl_command $($general_defaults.main_distro) -skip_win $true
}

wsl -d $($general_defaults.docker_distro) sudo groupadd --gid $local_user_groupid $local_user
wsl -d $($general_defaults.docker_distro) sudo adduser -G wheel --gid $local_user_groupid --uid $local_user_id $local_user --home "/mnt/wsl/instances/$($general_defaults.main_distro)/home/$local_user"
wsl -d $($general_defaults.docker_distro) sudo ln -s "/mnt/wsl/instances/$($general_defaults.main_distro)/home/$($local_user)/" "/home/$($local_user)/"

wsl -d $($general_defaults.main_distro) rm -Rf $($general_defaults.tmp_directory)