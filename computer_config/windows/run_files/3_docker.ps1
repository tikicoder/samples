
$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

# https://download.docker.com/win/static/stable/x86_64/
# https://lippertmarkus.com/2021/09/04/containers-without-docker-desktop/

$docker_Version = "docker-20.10.9.zip"
$tmp_dir = (Join-Path -Path "$([System.IO.Path]::GetTempPath())" -ChildPath "win_docker")
if (-not (Test-Path -Path $tmp_dir)) {New-Item -ItemType Directory -Path $tmp_dir}

$tmp_docker_save = $(Join-Path -Path $tmp_dir -ChildPath $docker_Version )
Write-Host  "Downloading $docker_Version and saving to $tmp_docker_save"
$webClient = [System.Net.WebClient]::new()
$webClient.DownloadFile("https://download.docker.com/win/static/stable/x86_64/$docker_Version", $tmp_docker_save)


if ( $(Get-Service | Where-Object {$_.Name -ieq "docker"} | Measure-Object).Count -gt 0 ){
  Stop-Service docker  
  $(Get-Service docker).WaitForStatus('Stopped')
  if ((Test-Path -Path "C:\docker")) {
    & C:\docker\dockerd --unregister-service
  }
}
if ((Test-Path -Path "C:\docker")) {Remove-Folder -path_to_delete "C:\docker" -Recurse $true}
try {
  if ((Test-Path -Path "C:\ProgramData\docker")) {Remove-Folder -path_to_delete "C:\ProgramData\docker" -Recurse $true}
}
catch {
  if (Test-Path -Path "C:\ProgramData\docker") { takeown.exe /F "C:\ProgramData\docker" /R /A /D Y }
  if (Test-Path -Path "C:\ProgramData\docker") { icacls "C:\ProgramData\docker\" /T /C /grant Administrators:F }
  if ((Test-Path -Path "C:\ProgramData\docker")) {Remove-Folder -path_to_delete "C:\ProgramData\docker" -Recurse $true}
}

Expand-Archive $tmp_docker_save -DestinationPath C:\ -Force
[Environment]::SetEnvironmentVariable("Path", "$($env:path);C:\docker", [System.EnvironmentVariableTarget]::Machine)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
dockerd --register-service
Start-Service docker

Remove-Item -Force -Confirm:$False -Recurse $tmp_dir

# https://docs.rockylinux.org/guides/interoperability/import_rocky_to_wsl_howto/
# I am using Rocky as my Docker Desktop App and will install Distrod on that
$tiki_docker_desktop_path = $(Join-Path -Path $HOME -ChildPath "AppData\Local\Packages\tiki_docker_desktop")

if ((Test-Path -Path $tiki_docker_desktop_path)) {
  Write-Host "There is an existing setup, please backup now if you want to keep - $tiki_docker_desktop_path"
  pause
  if ($(wsl -l | Where-Object {$_ -ieq 'tiki_docker_desktop'} | Measure-Object).Count -gt 0){
    wsl --terminate tiki_docker_desktop
    wsl --unregister tiki_docker_desktop
  }
  if ((Test-Path -Path $tiki_docker_desktop_path)) {
    Remove-Folder -path_to_delete $tiki_docker_desktop_path -Recurse $true
  }
  
}

New-Item -ItemType Directory -Path $tiki_docker_desktop_path
New-Item -ItemType Directory -Path $(Join-Path -Path $tiki_docker_desktop_path -ChildPath "LocalState")

wsl --import tiki_docker_desktop $(Join-Path -Path $tiki_docker_desktop_path -ChildPath "LocalState") $(Join-Path -Path $scriptPath_init -ChildPath "..\..\..\docker_images\rocky_linux\rocky-container.8.4.tar.gz")

$newUsername="tiki_docker"
wsl -d tiki_docker_desktop -e echo "connected"
wsl -d tiki_docker_desktop -e echo "connected"


if (Test-Path "\\wsl$\tiki_docker_desktop\usr\bin\tiki_auto_cert_update.sh"){Remove-Item -Path "\\wsl$\tiki_docker_desktop$\usr\bin\\tiki_auto_cert_update.sh"}
Write-Host "Coping Script auto_cert_update.sh"
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\auto_cert_update.sh") -Destination "\\wsl$\tiki_docker_desktop\usr\bin\tiki_auto_cert_update.sh"


$existing_repo_sslverify_check = $($(wsl -d tiki_docker_desktop grep -i "sslverify=" /etc/dnf/dnf.conf ) -Split '=')
$existing_repo_sslverify = ""
if ( $existing_repo_sslverify.Length -gt 1 ){
  if ( (-not ($existing_repo_sslverify[1] -ieq "false")) -and ( -not ($existing_repo_sslverify[1] -ieq "0"))){
    $existing_repo_sslverify = $existing_repo_sslverify[1]
  }
}


wsl -d tiki_docker_desktop -e sed -i '/sslverify/d' /etc/dnf/dnf.conf

wsl -d tiki_docker_desktop -e sed -i '$a sslverify=0' /etc/dnf/dnf.conf

wsl -d tiki_docker_desktop yum update -y
wsl -d tiki_docker_desktop yum install glibc-langpack-en -y
wsl -d tiki_docker_desktop yum install passwd sudo cracklib-dicts -y
wsl -d tiki_docker_desktop yum reinstall passwd sudo cracklib-dicts -y
wsl -d tiki_docker_desktop adduser -G wheel $newUsername
wsl -d tiki_docker_desktop echo -e "[user]" `>`> /etc/wsl.conf
wsl -d tiki_docker_desktop echo -e "default=$newUsername" `>`> /etc/wsl.conf
wsl -d tiki_docker_desktop echo -e "" `>`> /etc/wsl.conf
wsl -d tiki_docker_desktop echo -e "[automount]" `>`> /etc/wsl.conf
wsl -d tiki_docker_desktop echo -e "enabled = true" `>`> /etc/wsl.conf
wsl -d tiki_docker_desktop echo -e "options = `"metadata,uid=1003,gid=1003,umask=022,fmask=11,case=off`"" `>`> /etc/wsl.conf


wsl -d tiki_docker_desktop passwd $newUsername

wsl --terminate tiki_docker_desktop

wsl -d tiki_docker_desktop -e echo "connected"
wsl -d tiki_docker_desktop -e echo "connected"

wsl -d tiki_docker_desktop -e mkdir -p $general_defaults.tmp_directory

$docker_init_files = $(Get-ChildItem "$($scriptPath_init)/3_docker_*.sh" -File )
foreach ( $file in $docker_init_files){
  Write-Host "Coping File: $($file.Name) - \\wsl$\tiki_docker_desktop$($general_defaults.tmp_directory)\$($file.Name)"

  if (Test-Path "\\wsl$\tiki_docker_desktop$($general_defaults.tmp_directory)\$($file.Name)"){Remove-Item -Path "\\wsl$\tiki_docker_desktop$($general_defaults.tmp_directory)\$($file.Name)"}
  Copy-item -Path $file.FullName -Destination "\\wsl$\tiki_docker_desktop$($general_defaults.tmp_directory)\$($file.Name)"
}

if (Test-Path "\\wsl$\tiki_docker_desktop$($general_defaults.tmp_directory)\disable_sudo_pass.sh"){Remove-Item -Path "\\wsl$\tiki_docker_desktop$($general_defaults.tmp_directory)\disable_sudo_pass.sh"}
Write-Host "Coping Script disable_sudo_pass.sh"
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\disable_sudo_pass.sh") -Destination "\\wsl$\tiki_docker_desktop$($general_defaults.tmp_directory)\disable_sudo_pass.sh"


wsl -d tiki_docker_desktop -e bash "$($general_defaults.tmp_directory)/disable_sudo_pass.sh"

wsl -d tiki_docker_desktop mkdir -p "$($general_defaults.tmp_directory)/missing_certs"
Copy-Missing-Certs -DestinationTempFolderInDistro "$($general_defaults.tmp_directory)/missing_certs" -Distro tiki_docker_desktop -DestinationSSLFolderInDistro "/etc/pki/ca-trust/source/anchors/"

wsl -d tiki_docker_desktop -e sudo chmod 755 /usr/bin/tiki_auto_cert_update.sh
wsl -d tiki_docker_desktop -e sudo /usr/bin/tiki_auto_cert_update.sh

wsl -d tiki_docker_desktop sudo dnf check-update
wsl -d tiki_docker_desktop sudo dnf update -y

# Enable PowerTools Repository on Rocky Linux 8
# https://linuxways.net/red-hat/how-to-enable-powertools-repository-on-rocky-linux-8/
wsl -d tiki_docker_desktop sudo dnf install -y dnf-plugins-core
wsl -d tiki_docker_desktop sudo dnf install -y https://dl.fedoraproject.org/pub/epel/epel-release-latest-8.noarch.rpm
wsl -d tiki_docker_desktop sudo dnf config-manager --set-enabled powertools

wsl -d tiki_docker_desktop sudo bash "$($general_defaults.tmp_directory)/3_docker_Distrod.sh" "$($general_defaults.tmp_directory)"

# If you want to have this as part of auto win startup
# wsl -d tiki_docker_desktop sudo /opt/distrod/bin/distrod enable --start-on-windows-boot
wsl -d tiki_docker_desktop sudo /opt/distrod/bin/distrod enable 

wsl --terminate tiki_docker_desktop

wsl -d tiki_docker_desktop -e echo "connected"
wsl -d tiki_docker_desktop -e echo "connected"


wsl -d tiki_docker_desktop sudo dnf check-update
wsl -d tiki_docker_desktop sudo dnf update -y


wsl -d tiki_docker_desktop sudo bash "$($general_defaults.tmp_directory)/3_docker_Install.sh" "$newUsername"
wsl --terminate tiki_docker_desktop

wsl -d tiki_docker_desktop -e echo "connected"
wsl -d tiki_docker_desktop -e echo "connected"

wsl -d tiki_docker_desktop sudo bash "$($general_defaults.tmp_directory)/3_docker_updategroup.sh"
wsl --terminate tiki_docker_desktop

wsl -d tiki_docker_desktop -e echo "connected"
wsl -d tiki_docker_desktop -e echo "connected"

wsl -d tiki_docker_desktop sudo bash "$($general_defaults.tmp_directory)/3_docker_finalize.sh"
wsl --terminate tiki_docker_desktop

wsl -d tiki_docker_desktop -e echo "connected"
wsl -d tiki_docker_desktop -e echo "connected"


Write-Host "Removing DNF SSl Verification skip"
wsl -d tiki_docker_desktop -e sudo sed -i '/sslverify/d' /etc/dnf/dnf.conf

if ( -not [string]::IsNullorWhitespace($existing_repo_sslverify) ){
  Write-Host "Adding back previous sslverify setting: $($existing_repo_sslverify)"
  existing_repo_sslverify="'`$a sslverify=$($existing_repo_sslverify)'"
  wsl -d tiki_docker_desktop -e sudo sed -i $existing_repo_sslverify /etc/dnf/dnf.conf
}

Start-Sleep -s 2
Write-Host "Start Docker"
wsl -d tiki_docker_desktop sudo systemctl status dbus
wsl -d tiki_docker_desktop sudo systemctl start docker

Write-Host "Temp Directory Cleanup"
wsl -d tiki_docker_desktop -e sudo rm -Rf $($general_defaults.tmp_directory)


