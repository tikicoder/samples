$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

if (Test-Path "\\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"){Remove-Item -Path "\\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"}
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\\auto_cert_update.sh") -Destination "\\wsl$\$($general_defaults.docker_distro)$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"
wsl -d $($general_defaults.docker_distro) -e sudo mv "$($general_defaults.tmp_directory)/tiki_auto_cert_update.sh" /usr/bin/tiki_auto_cert_update.sh
wsl -d $($general_defaults.docker_distro) -e sudo chmod 755 /usr/bin/tiki_auto_cert_update.sh

wsl -d $($general_defaults.docker_distro) mkdir -p "$($general_defaults.tmp_directory)/missing_certs"
Copy-Missing-Certs -DestinationTempFolderInDistro "$($general_defaults.tmp_directory)/missing_certs" -Distro Ubuntu -DestinationSSLFolderInDistro "/usr/local/share/ca-certificates/"

wsl -d $($general_defaults.docker_distro) -e sudo cp "$($general_defaults.tmp_directory)/missing_certs/*.pem" 
wsl -d $($general_defaults.docker_distro) -e sudo /usr/bin/tiki_auto_cert_update.sh
