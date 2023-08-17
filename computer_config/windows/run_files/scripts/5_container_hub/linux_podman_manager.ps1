
function run-linux-docker {
  # https://docs.rockylinux.org/guides/interoperability/import_rocky_to_wsl/
  $rocky_v9_latest = "https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-Container-Base.latest.x86_64.tar.xz"
  $tmp_dir_hubimg = (Join-Path -Path "$([System.IO.Path]::GetTempPath())" -ChildPath "hub_image")
  if (-not (Test-Path -Path $tmp_dir_hubimg)) {New-Item -ItemType Directory -Path $tmp_dir_hubimg}


  Write-Host  "Downloading RockyLinux - $($rocky_v9_latest) and saving to $tmp_dir_hubimg"

  $docker_hub_image = $(Get-Download-Remote-File `
    -url_remote_file $rocky_v9_latest `
    -save_location $tmp_dir_hubimg)

  # I am using Rocky as my Docker Desktop App wsl v2 support systemd
  $path_tiki_container_desktop = $(Join-Path -Path $HOME -ChildPath "AppData\Local\Packages\$($general_defaults.docker.distro_name)")

  if ((Test-Path -Path $path_tiki_container_desktop)) {
    Write-Host "There is an existing setup, please backup now if you want to keep - $path_tiki_container_desktop"
    Write-Host "When you press entry the script will delete the old version"
    pause
    if ($(wsl -l | Where-Object {$_ -ieq $($general_defaults.docker.distro_name) -or $_ -ieq "$($general_defaults.docker.distro_name) (default)"} | Measure-Object).Count -gt 0){
      wsl --terminate $($general_defaults.docker.distro_name)
      wsl --unregister $($general_defaults.docker.distro_name)
    }
    if ((Test-Path -Path $path_tiki_container_desktop)) {
      Remove-Folder -path_to_delete $path_tiki_container_desktop -Recurse $true -Confirm:$False
    }
    
  }

  New-Item -ItemType Directory -Path $path_tiki_container_desktop
  New-Item -ItemType Directory -Path $(Join-Path -Path $path_tiki_container_desktop -ChildPath "LocalState")
  
  wsl --import "$($general_defaults.docker.distro_name)" "$(Join-Path -Path $path_tiki_container_desktop -ChildPath "LocalState")" "$docker_hub_image"
  Wait-Distro-Start -Distro $general_defaults.docker.distro_name

  if ((Test-Path -Path $tmp_dir_hubimg)) {
    Remove-Folder -path_to_delete $tmp_dir_hubimg -Recurse $true
  }

  if (Test-Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)\etc\wsl.conf"){Remove-Item -Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)\etc\wsl.conf"}
  Write-Host "Coping Conf $($general_defaults.docker.wsl_config)"
  Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\config\$($general_defaults.docker.wsl_config)") -Destination "$($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)\etc\wsl.conf"

  Write-Host "If you are running something like zScalar that overrides third party ssls, please turn it off"
  Write-Host "When you press entry the script attempt to continue"
  pause

  Wait-Distro-Start -Distro $general_defaults.docker.distro_name
  wsl -d $($general_defaults.docker.distro_name) -e sed -i "/^\[user\]$/a default=$($general_defaults.docker.username)" /etc/wsl.conf
  wsl -d $($general_defaults.docker.distro_name) -e sed -i "/^\[network\]$/a hostname=$($general_defaults.docker.host_name)" /etc/wsl.conf

  wsl -d $($general_defaults.docker.distro_name) dnf update -y
  wsl -d $($general_defaults.docker.distro_name) dnf install glibc-langpack-en -y
  wsl -d $($general_defaults.docker.distro_name) dnf install iproute net-tools procps-ng -y
  wsl -d $($general_defaults.docker.distro_name) dnf install passwd sudo cracklib-dicts -y
  wsl -d $($general_defaults.docker.distro_name) dnf reinstall passwd sudo cracklib-dicts -y
  wsl -d $($general_defaults.docker.distro_name) groupadd $($general_defaults.docker.username)
  wsl -d $($general_defaults.docker.distro_name) adduser -G wheel -g $($general_defaults.docker.username) $($general_defaults.docker.username)
  wsl -d $($general_defaults.docker.distro_name) passwd $($general_defaults.docker.username)

  Write-Host "If you are running something like zScalar that overrides third party ssls, you can turn it back on"
  Write-Host "When you press entry the script attempt to continue"
  pause

  wsl --terminate $($general_defaults.docker.distro_name)
  Wait-Distro-Start -Distro $general_defaults.docker.distro_name

  wsl -d $($general_defaults.docker.distro_name) -e mkdir -p $general_defaults.tmp_directory

  if (Test-Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"){Remove-Item -Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"}
  Write-Host "Coping Script auto_cert_update.sh"
  Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\auto_cert_update.sh") -Destination "$($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)$($general_defaults.tmp_directory)\auto_cert_update.sh"

  wsl -d $($general_defaults.docker.distro_name) mkdir -p "$($general_defaults.tmp_directory)/missing_certs"
  Copy-Missing-Certs -DestinationTempFolderInDistro "$($general_defaults.tmp_directory)/missing_certs" -Distro $($general_defaults.docker.distro_name) -DestinationSSLFolderInDistro "/etc/pki/ca-trust/source/anchors/"

  # disable password for sudo
  if (Test-Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"){Remove-Item -Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"}
  Write-Host "Coping Script disable_sudo_pass.sh"
  Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\disable_sudo_pass.sh") -Destination "$($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"
  wsl -d $($general_defaults.docker.distro_name) -e bash "$($general_defaults.tmp_directory)/disable_sudo_pass.sh"


  $wsl_init_files = $(Get-ChildItem "$($scripts_folder)/wsl_scripts/*.sh" -File )
  foreach ( $file in $wsl_init_files){
    Write-Host "Coping File: $($file.Name) - $($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)$($general_defaults.tmp_directory)\$($file.Name)"

    if (Test-Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)$($general_defaults.tmp_directory)\$($file.Name)"){Remove-Item -Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)$($general_defaults.tmp_directory)\$($file.Name)"}
    Copy-item -Path $file.FullName -Destination "$($general_defaults.wsl_share_path)\$($general_defaults.docker.distro_name)$($general_defaults.tmp_directory)\$($file.Name)"
  }

  wsl -d $($general_defaults.docker.distro_name) -e bash "$($general_defaults.tmp_directory)/init.sh" "$($general_defaults.tmp_directory)"

  wsl --terminate $($general_defaults.docker.distro_name)
  Wait-Distro-Start -Distro $general_defaults.docker.distro_name

  # Setup rest of PodMan here

  wsl -d $($general_defaults.docker.distro_name) -e bash "$($general_defaults.tmp_directory)/finalize.sh" "$($general_defaults.tmp_directory)"

}

