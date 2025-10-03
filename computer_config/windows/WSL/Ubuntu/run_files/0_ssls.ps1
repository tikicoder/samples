$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"

if (Test-Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"){Remove-Item -Path "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"}
Copy-item -Path $(Join-Path -Path $general_defaults.root_path -ChildPath "general\wsl\scripts\auto_cert_update.sh") -Destination "\\wsl$\$($general_defaults.main_distro)$($general_defaults.tmp_directory)\tiki_auto_cert_update.sh"
wsl -d $($general_defaults.main_distro) sudo mv "$($general_defaults.tmp_directory)/tiki_auto_cert_update.sh" /usr/bin/tiki_auto_cert_update.sh
wsl -d $($general_defaults.main_distro) sudo chown "root:root" /usr/bin/tiki_auto_cert_update.sh
wsl -d $($general_defaults.main_distro) sudo chmod 755 /usr/bin/tiki_auto_cert_update.sh

while(-not (Test-Path -Path "$($general_defaults.wsl_share_path)\$($general_defaults.main_distro)$($general_defaults.tmp_directory)/missing_certs")){
	Write-Host "Directory Missing - Distro: $($($general_defaults.main_distro)) - Path: $($general_defaults.tmp_directory)/missing_certs"
	wsl -d $($general_defaults.main_distro) -e mkdir -p "$($general_defaults.tmp_directory)/missing_certs"
}
Write-Host "Directory Exists - Distro: $($($general_defaults.main_distro)) - Path: $($general_defaults.tmp_directory)/missing_certs"

Copy-Missing-Certs -DestinationTempFolderInDistro "$($general_defaults.tmp_directory)/missing_certs" -Distro Ubuntu -DestinationSSLFolderInDistro "/usr/local/share/ca-certificates/"

wsl -d $($general_defaults.main_distro) sudo /usr/bin/tiki_auto_cert_update.sh

wsl --terminate $($general_defaults.main_distro)
Wait-Distro-Start -Distro $general_defaults.main_distro

wsl -d $general_defaults.main_distro sudo apt update 
wsl -d $general_defaults.main_distro sudo apt upgrade -y
