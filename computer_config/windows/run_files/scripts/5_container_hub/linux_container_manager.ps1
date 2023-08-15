
function run-linux {
  # https://docs.rockylinux.org/guides/interoperability/import_rocky_to_wsl/
  $rocky_v9_latest = "https://dl.rockylinux.org/pub/rocky/9/images/x86_64/Rocky-9-Container-Base.latest.x86_64.tar.xz"
  $tmp_dir_hubimg = (Join-Path -Path "$([System.IO.Path]::GetTempPath())" -ChildPath "hub_image")
  if (-not (Test-Path -Path $tmp_dir_hubimg)) {New-Item -ItemType Directory -Path $tmp_dir_hubimg}


  Write-Host  "Downloading RockyLinux - $($rocky_v9_latest) and saving to $tmp_dir_hubimg"

  $docker_hub_image = $(Get-Download-Remote-File `
    -url_remote_file $rocky_v9_latest `
    -save_location $tmp_dir_hubimg)

  # I am using Rocky as my Docker Desktop App wsl v2 support systemd
  $path_tiki_container_desktop = $(Join-Path -Path $HOME -ChildPath "AppData\Local\Packages\$($general_defaults.docker_distro)")

  if ((Test-Path -Path $path_tiki_container_desktop)) {
    Write-Host "There is an existing setup, please backup now if you want to keep - $path_tiki_container_desktop"
    Write-Host "When you press entry the script will delete the old version"
    pause
    if ($(wsl -l | Where-Object {$_ -ieq $($general_defaults.docker_distro) -or $_ -ieq "$($general_defaults.docker_distro) (default)"} | Measure-Object).Count -gt 0){
      wsl --terminate $($general_defaults.docker_distro)
      wsl --unregister $($general_defaults.docker_distro)
    }
    if ((Test-Path -Path $path_tiki_container_desktop)) {
      Remove-Folder -path_to_delete $path_tiki_container_desktop -Recurse $true
    }
    
  }

  New-Item -ItemType Directory -Path $path_tiki_container_desktop
  New-Item -ItemType Directory -Path $(Join-Path -Path $path_tiki_container_desktop -ChildPath "LocalState")
  
  wsl --import "$($general_defaults.docker_distro)" "$(Join-Path -Path $path_tiki_container_desktop -ChildPath "LocalState")" "$docker_hub_image"
  Wait-Distro-Start -Distro $general_defaults.docker_distro

  $newUsername="tiki_container"

  if (Test-Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)\etc\wsl.conf"){Remove-Item -Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)\etc\wsl.conf"}
  Write-Host "Coping Conf docker.WSL.conf"
  Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\config\docker.wsl.conf") -Destination "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)\etc\wsl.conf"

  Write-Host "If you are running something like zScalar that overrides third party ssls, please turn it off"
  Write-Host "When you press entry the script attempt to continue"
  pause

  Wait-Distro-Start -Distro $general_defaults.docker_distro
  wsl -d $($general_defaults.docker_distro) -e sed -i "/^\[user\]$/a default=$newUsername" /etc/wsl.conf

  wsl -d $($general_defaults.docker_distro) dnf update -y
  wsl -d $($general_defaults.docker_distro) dnf install glibc-langpack-en -y
  wsl -d $($general_defaults.docker_distro) dnf install iproute net-tools procps-ng -y
  wsl -d $($general_defaults.docker_distro) dnf install passwd sudo cracklib-dicts -y
  wsl -d $($general_defaults.docker_distro) dnf reinstall passwd sudo cracklib-dicts -y
  wsl -d $($general_defaults.docker_distro) groupadd --gid $general_defaults.user_info.gid $newUsername
  wsl -d $($general_defaults.docker_distro) adduser -G wheel --gid $general_defaults.user_info.gid --uid $general_defaults.user_info.uid $newUsername
  wsl -d $($general_defaults.docker_distro) passwd $newUsername

  Write-Host "If you are running something like zScalar that overrides third party ssls, please turn it off"
  Write-Host "When you press entry the script attempt to continue"
  pause

  wsl --terminate $($general_defaults.docker_distro)
  Wait-Distro-Start -Distro $general_defaults.docker_distro

  wsl -d $($general_defaults.docker_distro) -e mkdir -p $general_defaults.tmp_directory

  if (Test-Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"){Remove-Item -Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"}
  Write-Host "Coping Script auto_cert_update.sh"
  Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\auto_cert_update.sh") -Destination "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\auto_cert_update.sh"

  wsl -d $($general_defaults.docker_distro) mkdir -p "$($general_defaults.tmp_directory)/missing_certs"
  Copy-Missing-Certs -DestinationTempFolderInDistro "$($general_defaults.tmp_directory)/missing_certs" -Distro $($general_defaults.docker_distro) -DestinationSSLFolderInDistro "/etc/pki/ca-trust/source/anchors/"

  # disable password for sudo
  if (Test-Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"){Remove-Item -Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"}
  Write-Host "Coping Script disable_sudo_pass.sh"
  Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\disable_sudo_pass.sh") -Destination "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\disable_sudo_pass.sh"
  wsl -d $($general_defaults.docker_distro) -e bash "$($general_defaults.tmp_directory)/disable_sudo_pass.sh"


  $wsl_init_files = $(Get-ChildItem "$($scripts_folder)/wsl_scripts/*.sh" -File )
  foreach ( $file in $wsl_init_files){
    Write-Host "Coping File: $($file.Name) - $($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\$($file.Name)"

    if (Test-Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\$($file.Name)"){Remove-Item -Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\$($file.Name)"}
    Copy-item -Path $file.FullName -Destination "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\$($file.Name)"
  }

  wsl -d $($general_defaults.docker_distro) -e sudo bash "$($general_defaults.tmp_directory)/init.sh"

  Write-Host "If you are running something like zScalar that overrides third party ssls, please turn it back on"
  Write-Host "When you press entry the script attempt to continue"
  pause

  wsl --terminate $($general_defaults.docker_distro)
  Wait-Distro-Start -Distro $general_defaults.docker_distro

  wsl -d $($general_defaults.docker_distro) -e sudo bash "$($general_defaults.tmp_directory)/container_init.sh" 36257
  wsl -d $($general_defaults.docker_distro) -e sudo bash "$($general_defaults.tmp_directory)/finalize.sh" "$($general_defaults.tmp_directory)"


}













# wsl -d $($general_defaults.docker_distro) bash "$($general_defaults.tmp_directory)/$($file_prefix)init.sh" "$($general_defaults.tmp_directory)"

# wsl -d $($general_defaults.docker_distro) bash "$($general_defaults.tmp_directory)/$($file_prefix)Install.sh" "$newUsername" "$($general_defaults.docker_sock)" "$($general_defaults.docker_host_sock)"
# wsl --terminate $($general_defaults.docker_distro)
# Wait-Distro-Start -Distro $general_defaults.docker_distro

# wsl -d $($general_defaults.docker_distro) bash "$($general_defaults.tmp_directory)/$($file_prefix)updategroup.sh"
# wsl --terminate $($general_defaults.docker_distro)
# Wait-Distro-Start -Distro $general_defaults.docker_distro

# wsl -d $($general_defaults.docker_distro) bash "$($general_defaults.tmp_directory)/$($file_prefix)finalize.sh" "$($general_defaults.docker_dir)" "$($general_defaults.docker_host_sock)" "$($general_defaults.docker_host_tcp)"
# wsl --terminate $($general_defaults.docker_distro)
# Wait-Distro-Start -Distro $general_defaults.docker_distro


# Write-Host "Removing DNF SSl Verification skip"
# wsl -d $($general_defaults.docker_distro) -e sudo sed -i '/sslverify/d' /etc/dnf/dnf.conf

# if ( -not [string]::IsNullorWhitespace($existing_repo_sslverify) ){
#   Write-Host "Adding back previous sslverify setting: $($existing_repo_sslverify)"
#   existing_repo_sslverify="'`$a sslverify=$($existing_repo_sslverify)'"
#   wsl -d $($general_defaults.docker_distro) -e sudo sed -i $existing_repo_sslverify /etc/dnf/dnf.conf
# }

# Start-Sleep -s 2
# Write-Host "Start Docker"
# wsl -d $($general_defaults.docker_distro) sudo systemctl start dbus
# wsl -d $($general_defaults.docker_distro) sudo systemctl start docker

# if (Test-Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\user_docker_init.sh"){Remove-Item -Path "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\user_docker_init.sh"}
# Write-Host "Coping Script disable_sudo_pass.sh"
# Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\user_docker_init.sh") -Destination "$($general_defaults.wsl_share_path)\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\user_docker_init.sh"
# wsl -d $($general_defaults.docker_distro) bash "$($general_defaults.tmp_directory)/user_docker_init.sh" "'$($general_defaults.docker_sock)'" "'$($general_defaults.docker_host_sock)'" "'$($general_defaults.docker_distro)'" "'$($general_defaults.docker_dir)'" "$($general_defaults.docker_gropuid)"


# Write-Host "Temp Directory Cleanup"
# wsl -d $($general_defaults.docker_distro) -e sudo rm -Rf $($general_defaults.tmp_directory)

# docker context create lin --docker host=$($general_defaults.docker_host_tcp)
