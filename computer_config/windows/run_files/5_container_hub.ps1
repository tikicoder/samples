# Switch from Docker to minikube and install kaniko 
# MiniKube
# https://minikube.sigs.k8s.io/docs/start/
# supports multinode, the biggest issue is windows
# https://github.com/vrapolinario/MinikubeWindowsContainers

# Kaniko 
# https://github.com/GoogleContainerTools/kaniko
# is designed to build container images inside of K8s from a docker file.

# Rocky Linux has preexported files for download
# https://docs.rockylinux.org/guides/interoperability/import_rocky_to_wsl/

# https://download.docker.com/win/static/stable/x86_64/
# https://lippertmarkus.com/2021/09/04/containers-without-docker-desktop/
# IF you would like to role your own I do have a script about helping with the export strait from docker hub
# ~/docker_images\os\linux\rocky_linux\


$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"


if(-not $is_admin_context ){
  Write-Host "running as Admin"
  start-process -verb runas -ArgumentList "-Command $($scriptPath_init)\$($MyInvocation.MyCommand.Name)" pwsh
  exit
}

$section_prefix = "5_container_hub"

$scripts_folder = "$(Join-Path -Path $scriptPath_init -ChildPath "scripts\$($section_prefix)")"

# . "$(Join-Path -Path $scripts_folder -ChildPath "win_container_manager.ps1")"
# run-windows

. "$(Join-Path -Path $scripts_folder -ChildPath "linux_docker_manager.ps1")"
run-linux-docker

# Windows 11 supports nested virtulization for WSL. So once I am on Windows 11 I think some of this will go away.
# https://learn.microsoft.com/en-us/windows/wsl/wsl-config#configuration-setting-for-wslconfig
# That looks to hopfully allow minikube to run in kvm via wsl
# https://minikube.sigs.k8s.io/docs/drivers/
# podman is not a good alternative since it is experimental. Docker is not allowed at my current job.

# could user hyperv to install ubuntu 22.04 server
# The issue is WSL and Hyper-V Vms do not communicate by default.
# If you setup a Hyper-V VM and was WSL to communicate with it. Set the Hyper-v to the default switch and then run the following
# Get-NetIPInterface | where {$_.InterfaceAlias -eq 'vEthernet (WSL)' -or $_.InterfaceAlias -eq 'vEthernet (Default Switch)'} | Set-NetIPInterface -Forwarding Enabled -Verbose

# if you restart the hyper-v vm the WSL should be able to ping and ssh to the IP.

# To enable netsed Virtualization on Hyper-V you can run
# Set-VMProcessor -VMName MiniKube -ExposeVirtualizationExtensions $true