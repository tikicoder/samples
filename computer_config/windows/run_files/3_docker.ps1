
$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

# https://download.docker.com/win/static/stable/x86_64/
# https://lippertmarkus.com/2021/09/04/containers-without-docker-desktop/

$docker_Version = "docker-20.10.9.zip"
$tmp_dir = (Join-Path "$([System.IO.Path]::GetTempPath())" "win_docker")
if (-not (Test-Path -Path $tmp_dir)) {New-Item -ItemType Directory -Path $tmp_dir}
$webClient = [System.Net.WebClient]::new()
$webClient.DownloadFile("https://download.docker.com/win/static/stable/x86_64/$docker_Version ", $(Join-Path -Path $tmp_dir -ChilePath $docker_Version  ))



Expand-Archive $(Join-Path -Path $tmp_dir -ChilePath $docker_Version  ) -DestinationPath C:\
[Environment]::SetEnvironmentVariable("Path", "$($env:path);C:\docker", [System.EnvironmentVariableTarget]::Machine)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
dockerd --register-service
Start-Service docker

Remove-Item -Force -Confirm:$False -Recurse $tmp_dir

# https://docs.rockylinux.org/guides/interoperability/import_rocky_to_wsl_howto/
# I am using Rocky as my Docker Desktop App and will install Distrod on that
$tiki_docker_desktop_path = $(Join-Path -Path $HOME -ChildPath "AppData\Local\Packages\tiki_docker_desktop")
if (-not (Test-Path -Path $(Join-Path -Path $HOME -ChildPath "AppData\Local\Packages\tiki_docker_desktop"))) {
  New-Item -ItemType Directory -Path $tiki_docker_desktop_path
  wsl --import tiki_docker_desktop $tiki_docker_desktop_path $(Join-Path -Path $scriptPath_init -ChildPath "..\..\..\docker_images\rocky_linux\rocky-container.8.4.tar.gz")
}

newUsername="tiki_docker"

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
