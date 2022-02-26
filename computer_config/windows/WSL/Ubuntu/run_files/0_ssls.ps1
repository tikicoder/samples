$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

if (Test-Path "\\wsl$\tiki_docker_desktop$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"){Remove-Item -Path "\\wsl$\tiki_docker_desktop$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"}
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\auto_cert_update.sh") -Destination "\\wsl$\tiki_docker_desktop$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"
wsl -d tiki_docker_desktop -e sudo mv "$($general_defaults.tmp_directory)/tiki_auto_cert_update.sh" /usr/bin/tiki_auto_cert_update.sh
wsl -d tiki_docker_desktop -e sudo chmod 755 /usr/bin/tiki_auto_cert_update.sh

wsl -d tiki_docker_desktop mkdir -p "$($general_defaults.tmp_directory)/missing_certs"
Copy-Missing-Certs -DestinationTempFolderInDistro "$($general_defaults.tmp_directory)/missing_certs" -Distro Ubuntu -DestinationSSLFolderInDistro "/usr/local/share/ca-certificates/"

wsl -d tiki_docker_desktop -e sudo cp "$($general_defaults.tmp_directory)/missing_certs/*.pem" 
wsl -d tiki_docker_desktop -e sudo /usr/bin/tiki_auto_cert_update.sh
