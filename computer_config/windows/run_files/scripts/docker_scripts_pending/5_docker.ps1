# Switch from Docker to minikube and install kaniko 
# MiniKube
# https://minikube.sigs.k8s.io/docs/start/
# supports multinode, the biggest issue is windows
# https://github.com/vrapolinario/MinikubeWindowsContainers

# Kaniko 
# https://github.com/GoogleContainerTools/kaniko
# is designed to build container images inside of K8s from a docker file.


$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

# https://download.docker.com/win/static/stable/x86_64/
# https://lippertmarkus.com/2021/09/04/containers-without-docker-desktop/

$hub_image_version = "8.7"
$docker_hub_image = $(Join-Path -Path $scriptPath_init -ChildPath "..\..\..\docker_images\os\linux\rocky_linux\rocky-container.$($hub_image_version).tar.gz")
if (-not (Test-Path -Path $docker_hub_image)) {
  Write-Host "Could not find docker hub image $($docker_hub_image)"
  exit
}

new-localgroup -name "docker-users"
Add-LocalGroupMember -Group "docker-users" -Member ([System.Security.Principal.WindowsIdentity]::GetCurrent().Name)

$docker_hub_image_main = $($docker_hub_image  | Resolve-Path)
$docker_Version = "docker-23.0.3.zip  "
$tmp_dir_docker = (Join-Path -Path "$([System.IO.Path]::GetTempPath())" -ChildPath "win_docker")
$tmp_dir_hubimg = (Join-Path -Path "$([System.IO.Path]::GetTempPath())" -ChildPath "hub_image")
$docker_storage_dir = "C:\ProgramData\docker"
if (-not (Test-Path -Path $tmp_dir_docker)) {New-Item -ItemType Directory -Path $tmp_dir_docker}
if (-not (Test-Path -Path $tmp_dir_hubimg)) {New-Item -ItemType Directory -Path $tmp_dir_hubimg}

$docker_hub_image = (Join-Path -Path "$tmp_dir_hubimg" -ChildPath "hub_image.tar.gz")
Copy-Item -Force -Path $docker_hub_image_main -Destination $docker_hub_image

$tmp_docker_save = $(Join-Path -Path $tmp_dir_docker -ChildPath $docker_Version )
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
  if ((Test-Path -Path $docker_storage_dir)) {Remove-Folder -path_to_delete $docker_storage_dir -Recurse $true}
}
catch {
  if (Test-Path -Path $docker_storage_dir) { takeown.exe /F $docker_storage_dir /R /A /D Y }
  if (Test-Path -Path $docker_storage_dir) { icacls "$($docker_storage_dir)\" /T /C /grant Administrators:F }
  if ((Test-Path -Path $docker_storage_dir)) {Remove-Folder -path_to_delete $docker_storage_dir -Recurse $true}
  if ((Test-Path -Path "$($docker_storage_dir)\config")) {Remove-Folder -path_to_delete "$($docker_storage_dir)\config" -Recurse $true}
}

if ((Test-Path -Path "$($docker_storage_dir)\config")) {
  Write-Host "Existing Docker Config still exists"
}

Expand-Archive $tmp_docker_save -DestinationPath C:\ -Force
[Environment]::SetEnvironmentVariable("Path", "$($env:path);C:\docker", [System.EnvironmentVariableTarget]::Machine)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
dockerd --register-service
Start-Service docker
WaitUntilServices "Docker Engine" "Running"

if (-not (Test-Path -Path "$($docker_storage_dir)\config")) {
  if (Test-Path -Path $docker_storage_dir) { 
    New-Item -ItemType Directory -Path $docker_storage_dir
  }
  # Doc for more config settings
  # https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/configure-docker-daemon
  New-Item -ItemType Directory -Path "$($docker_storage_dir)\config"
  Copy-Item -Force -Path "..\general\docker\daemon.json" -Destination "$($docker_storage_dir)\config\daemon.json"
  Stop-Service docker
  WaitUntilServices "Docker Engine" "Stopped"
  
  Start-Service docker
  WaitUntilServices "Docker Engine" "Running"
}

Remove-Item -Force -Confirm:$False -Recurse $tmp_dir_docker

# https://docs.rockylinux.org/guides/interoperability/import_rocky_to_wsl_howto/
# I am using Rocky as my Docker Desktop App and will install Distrod on that
$path_tiki_docker_desktop = $(Join-Path -Path $HOME -ChildPath "AppData\Local\Packages\$($general_defaults.docker_distro)")

if ((Test-Path -Path $path_tiki_docker_desktop)) {
  Write-Host "There is an existing setup, please backup now if you want to keep - $path_tiki_docker_desktop"
  pause
  if ($(wsl -l | Where-Object {$_ -ieq $($general_defaults.docker_distro) -or $_ -ieq "$($general_defaults.docker_distro) (default)"} | Measure-Object).Count -gt 0){
    wsl --terminate $($general_defaults.docker_distro)
    wsl --unregister $($general_defaults.docker_distro)
  }
  if ((Test-Path -Path $path_tiki_docker_desktop)) {
    Remove-Folder -path_to_delete $path_tiki_docker_desktop -Recurse $true
  }
  
}

New-Item -ItemType Directory -Path $path_tiki_docker_desktop
New-Item -ItemType Directory -Path $(Join-Path -Path $path_tiki_docker_desktop -ChildPath "LocalState")

wsl --import $($general_defaults.docker_distro) $(Join-Path -Path $path_tiki_docker_desktop -ChildPath "LocalState") $docker_hub_image --version 2
Remove-Item -Force -Confirm:$False -Recurse $tmp_dir_hubimg

$newUsername="tiki_docker"
Wait-Distro-Start -Distro $general_defaults.docker_distro


if (Test-Path "\\wsl$\$($general_defaults.docker_distro)\usr\bin\tiki_auto_cert_update.sh"){Remove-Item -Path "\\wsl$\$($general_defaults.docker_distro)\usr\bin\tiki_auto_cert_update.sh"}
Write-Host "Coping Script auto_cert_update.sh"
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\auto_cert_update.sh") -Destination "\\wsl$\$($general_defaults.docker_distro)\usr\bin\tiki_auto_cert_update.sh"

if (Test-Path "\\wsl$\$($general_defaults.docker_distro)\etc\wsl.conf"){Remove-Item -Path "\\wsl$\$($general_defaults.docker_distro)\etc\wsl.conf"}
Write-Host "Coping Conf docker.WSL.conf"
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\config\docker.wsl.conf") -Destination "\\wsl$\$($general_defaults.docker_distro)\etc\wsl.conf"


$existing_repo_sslverify_check = $($(wsl -d $($general_defaults.docker_distro) grep -i "sslverify=" /etc/dnf/dnf.conf ) -Split '=')
$existing_repo_sslverify = ""
if ( $existing_repo_sslverify.Length -gt 1 ){
  if ( (-not ($existing_repo_sslverify[1] -ieq "false")) -and ( -not ($existing_repo_sslverify[1] -ieq "0"))){
    $existing_repo_sslverify = $existing_repo_sslverify[1]
  }
}


wsl -d $($general_defaults.docker_distro) -e sed -i '/sslverify/d' /etc/dnf/dnf.conf

wsl -d $($general_defaults.docker_distro) -e sed -i '$a sslverify=0' /etc/dnf/dnf.conf

wsl -d $($general_defaults.docker_distro) -e sed -i "/^\[user\]$/a default=$newUsername" /etc/wsl.conf

wsl -d $($general_defaults.docker_distro) dnf update -y
wsl -d $($general_defaults.docker_distro) dnf install glibc-langpack-en -y
wsl -d $($general_defaults.docker_distro) dnf install iproute net-tools procps-ng -y
wsl -d $($general_defaults.docker_distro) dnf install passwd sudo cracklib-dicts -y
wsl -d $($general_defaults.docker_distro) dnf reinstall passwd sudo cracklib-dicts -y
wsl -d $($general_defaults.docker_distro) groupadd --gid $general_defaults.user_info.gid $newUsername
wsl -d $($general_defaults.docker_distro) adduser -G wheel --gid $general_defaults.user_info.gid --uid $general_defaults.user_info.uid $newUsername
wsl -d $($general_defaults.docker_distro) passwd $newUsername

wsl --terminate $($general_defaults.docker_distro)
Wait-Distro-Start -Distro $general_defaults.docker_distro


wsl -d $($general_defaults.docker_distro) -e mkdir -p $general_defaults.tmp_directory

$file_prefix = "5_docker_"

$docker_init_files = $(Get-ChildItem "$($scriptPath_init)/$($file_prefix)*.sh" -File )
foreach ( $file in $docker_init_files){
  Write-Host "Coping File: $($file.Name) - \\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\$($file.Name)"

  if (Test-Path "\\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\$($file.Name)"){Remove-Item -Path "\\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\$($file.Name)"}
  Copy-item -Path $file.FullName -Destination "\\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\$($file.Name)"
}

if (Test-Path "\\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"){Remove-Item -Path "\\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"}
Write-Host "Coping Script disable_sudo_pass.sh"
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\disable_sudo_pass.sh") -Destination "\\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"


wsl -d $($general_defaults.docker_distro) -e bash "$($general_defaults.tmp_directory)/disable_sudo_pass.sh"

# Enable PowerTools Repository on Rocky Linux 8
# https://linuxways.net/red-hat/how-to-enable-powertools-repository-on-rocky-linux-8/
# needed to install docker
wsl -d $($general_defaults.docker_distro) sudo dnf install -y dnf-plugins-core
wsl -d $($general_defaults.docker_distro) sudo dnf config-manager --set-enabled powertools

# Enable EPEL repo
# https://docs.fedoraproject.org/en-US/epel/#How_can_I_use_these_extra_packages.3F
wsl -d $($general_defaults.docker_distro) sudo dnf install -y epel-release

wsl -d $($general_defaults.docker_distro) -e sudo dnf upgrade -y

wsl -d $($general_defaults.docker_distro) mkdir -p "$($general_defaults.tmp_directory)/missing_certs"
Copy-Missing-Certs -DestinationTempFolderInDistro "$($general_defaults.tmp_directory)/missing_certs" -Distro $($general_defaults.docker_distro) -DestinationSSLFolderInDistro "/etc/pki/ca-trust/source/anchors/"

wsl -d $($general_defaults.docker_distro) -e sudo chmod 755 /usr/bin/tiki_auto_cert_update.sh
wsl -d $($general_defaults.docker_distro) -e sudo /usr/bin/tiki_auto_cert_update.sh

wsl -d $($general_defaults.docker_distro) sudo dnf check-update
wsl -d $($general_defaults.docker_distro) sudo dnf update -y

wsl --terminate $($general_defaults.docker_distro)
Wait-Distro-Start -Distro $general_defaults.docker_distro

wsl -d $($general_defaults.docker_distro) -e sudo dnf remove --oldinstallonly --setopt installonly_limit=2 kernel
# This should not be needed with the latest version of WSL it suppoerts systemd by default
# wsl -d $($general_defaults.docker_distro) sudo bash "$($general_defaults.tmp_directory)/$($file_prefix)Distrod.sh" "$($general_defaults.tmp_directory)"

# If you want to have this as part of auto win startup
# wsl -d $($general_defaults.docker_distro) sudo /opt/distrod/bin/distrod enable --start-on-windows-boot
# wsl -d $($general_defaults.docker_distro) sudo /opt/distrod/bin/distrod enable 

wsl --terminate $($general_defaults.docker_distro)
Wait-Distro-Start -Distro $general_defaults.docker_distro


wsl -d $($general_defaults.docker_distro) bash "$($general_defaults.tmp_directory)/$($file_prefix)init.sh" "$($general_defaults.tmp_directory)"

wsl -d $($general_defaults.docker_distro) bash "$($general_defaults.tmp_directory)/$($file_prefix)Install.sh" "$newUsername" "$($general_defaults.docker_sock)" "$($general_defaults.docker_host_sock)"
wsl --terminate $($general_defaults.docker_distro)
Wait-Distro-Start -Distro $general_defaults.docker_distro

wsl -d $($general_defaults.docker_distro) bash "$($general_defaults.tmp_directory)/$($file_prefix)updategroup.sh"
wsl --terminate $($general_defaults.docker_distro)
Wait-Distro-Start -Distro $general_defaults.docker_distro

wsl -d $($general_defaults.docker_distro) bash "$($general_defaults.tmp_directory)/$($file_prefix)finalize.sh" "$($general_defaults.docker_dir)" "$($general_defaults.docker_host_sock)" "$($general_defaults.docker_host_tcp)"
wsl --terminate $($general_defaults.docker_distro)
Wait-Distro-Start -Distro $general_defaults.docker_distro


Write-Host "Removing DNF SSl Verification skip"
wsl -d $($general_defaults.docker_distro) -e sudo sed -i '/sslverify/d' /etc/dnf/dnf.conf

if ( -not [string]::IsNullorWhitespace($existing_repo_sslverify) ){
  Write-Host "Adding back previous sslverify setting: $($existing_repo_sslverify)"
  existing_repo_sslverify="'`$a sslverify=$($existing_repo_sslverify)'"
  wsl -d $($general_defaults.docker_distro) -e sudo sed -i $existing_repo_sslverify /etc/dnf/dnf.conf
}

Start-Sleep -s 2
Write-Host "Start Docker"
wsl -d $($general_defaults.docker_distro) sudo systemctl start dbus
wsl -d $($general_defaults.docker_distro) sudo systemctl start docker

if (Test-Path "\\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\user_docker_init.sh"){Remove-Item -Path "\\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\user_docker_init.sh"}
Write-Host "Coping Script disable_sudo_pass.sh"
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\user_docker_init.sh") -Destination "\\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\user_docker_init.sh"
wsl -d $($general_defaults.docker_distro) bash "$($general_defaults.tmp_directory)/user_docker_init.sh" "'$($general_defaults.docker_sock)'" "'$($general_defaults.docker_host_sock)'" "'$($general_defaults.docker_distro)'" "'$($general_defaults.docker_dir)'" "$($general_defaults.docker_gropuid)"


Write-Host "Temp Directory Cleanup"
wsl -d $($general_defaults.docker_distro) -e sudo rm -Rf $($general_defaults.tmp_directory)

docker context create lin --docker host=$($general_defaults.docker_host_tcp)
