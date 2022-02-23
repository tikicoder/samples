
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
$webClient.DownloadFile("https://download.docker.com/win/static/stable/x86_64/$docker_Version ", $tmp_docker_save)


if ((Test-Path -Path "C:\docker")) {Remove-Item -Path "C:\docker" -Recurse -Force}
Expand-Archive $tmp_docker_save -DestinationPath C:\
[Environment]::SetEnvironmentVariable("Path", "$($env:path);C:\docker", [System.EnvironmentVariableTarget]::Machine)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
dockerd --register-service
Start-Service docker

Remove-Item -Force -Confirm:$False -Recurse $tmp_dir

# https://docs.rockylinux.org/guides/interoperability/import_rocky_to_wsl_howto/
# I am using Rocky as my Docker Desktop App and will install Distrod on that
$tiki_docker_desktop_path = $(Join-Path -Path $HOME -ChildPath "AppData\Local\Packages\tiki_docker_desktop")
if ($(wsl -l | Where-Object {$_ -ieq 'tiki_docker_desktop'} | Measure-Object).Count -gt 0){
  wsl --unregister tiki_docker_desktop
}

if ((Test-Path -Path $tiki_docker_desktop_path)) {
  Write-Host "There is an existing setup, please backup now if you want to keep - $tiki_docker_desktop_path"
  pause
  if ((Test-Path -Path $tiki_docker_desktop_path)) {
    Remove-Item -Path $tiki_docker_desktop_path -Recurse -Force
  }
  
}

New-Item -ItemType Directory -Path $tiki_docker_desktop_path
wsl --import tiki_docker_desktop $tiki_docker_desktop_path $(Join-Path -Path $scriptPath_init -ChildPath "..\..\..\docker_images\rocky_linux\rocky-container.8.4.tar.gz")

$newUsername="tiki_docker"

wsl -d tiki_docker_desktop yum update
wsl -d tiki_docker_desktop yum install glibc-langpack-en -y
wsl -d tiki_docker_desktop yum reinstall passwd sudo cracklib-dicts -y
wsl -d tiki_docker_desktop adduser -G wheel $newUsername
wsl -d tiki_docker_desktop echo -e "[user]" `>`> /etc/wsl.conf
wsl -d tiki_docker_desktop echo -e "default=$newUsername" `>`> /etc/wsl.conf
wsl -d tiki_docker_desktop echo -e "" `>`> /etc/wsl.conf
wsl -d tiki_docker_desktop echo -e "[automount]" `>`> /etc/wsl.conf
wsl -d tiki_docker_desktop echo -e "enabled = true" `>`> /etc/wsl.conf
wsl -d tiki_docker_desktop echo -e "options = `"metadata,uid=1003,gid=1003,umask=022,fmask=11,case=off`"" `>`> /etc/wsl.conf



wsl -d tiki_docker_desktop passwd $newUsername

wsl --shutdown
wsl -d tiki_docker_desktop echo "connected"

$missing_root_certs_path = $(Join-Path -Path $general_defaults.root_path -ChildPath 'general\missing_root_certs' )
$missing_root_certs = $(Get-Childitem -Path $missing_root_certs_path -File | Where-Object {$_.Name.ToLower().EndsWith(".crt")})

foreach ( $file in $missing_root_certs){
  Copy-item -Path $file.FullName -Destination "\\wsl$\Ubuntu\etc\pki\ca-trust\source$($file.Name)"
}


wsl -d tiki_docker_desktop sudo update-ca-trust

wsl -d tiki_docker_desktop sudo dnf check-update
wsl -d tiki_docker_desktop sudo dnf update -y

wsl -d tiki_docker_desktop mkdir -p $general_defaults.tmp_directory

if (Test-Path "\\wsl$\tiki_docker_desktop\$($general_defaults.tmp_directory)\distrod_install.sh"){Remove-Item -Path "\\wsl$\tiki_docker_desktop\$($general_defaults.tmp_directory)\distrod_install.sh"}
Copy-item -Path $(Join-Path -Path $scriptPath_init -ChildPath "3_docker_Distrod.sh") -Destination "\\wsl$\tiki_docker_desktop\$($general_defaults.tmp_directory)\distrod_install.sh"

if (Test-Path "\\wsl$\tiki_docker_desktop\$($general_defaults.tmp_directory)\distrod_install.sh"){Remove-Item -Path "\\wsl$\tiki_docker_desktop\$($general_defaults.tmp_directory)\distrod_update.sh"}
Copy-item -Path $(Join-Path -Path $scriptPath_init -ChildPath "3_docker_Distrod_update.sh") -Destination "\\wsl$\tiki_docker_desktop\$($general_defaults.tmp_directory)\distrod_update.sh"

wsl -d tiki_docker_desktop $($general_defaults.tmp_directory)\distrod_install.sh
wsl -d tiki_docker_desktop rm -Rf $($general_defaults.tmp_directory)

wsl --terminate tiki_docker_desktop
wsl -d tiki_docker_desktop echo "connected"