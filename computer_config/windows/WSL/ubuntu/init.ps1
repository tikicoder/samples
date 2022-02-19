$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition


# wsl --set-default-version 2

# # Configures mem limit on WSL Config
# "[wsl2]" >> "$HOME/.wslconfig"
# "memory=2GB" >> "$HOME/.wslconfig"
# "swap=512MB" >> "$HOME/.wslconfig"

$missing_root_certs_path = $(Join-Path -Path $scriptPath_init -ChildPath '..\missing_root_certs' )
$missing_root_certs = $(Get-Childitem -Path $missing_root_certs_path -File | Where-Object {$_.Name.ToLower().EndsWith(".crt")})

$tmp_setup_path = "/tmp/general_setup_config"
Ubuntu run "mkdir -p $tmp_setup_path"
Ubuntu run "mkdir -p $tmp_setup_path/missing_root_certs"

Copy-item -Path $(Join-Path -Path $scriptPath_init -ChildPath "init.sh") -Destination "\\wsl$\Ubuntu\$tmp_setup_path\init.sh"
Ubuntu run "chmod 755 $tmp_setup_path/init.sh"

foreach ( $file in $missing_root_certs){
  Copy-item -Path $file.FullName -Destination "\\wsl$\Ubuntu\$tmp_setup_path\missing_root_certs\$($file.Name)"
}


Ubuntu run "sudo $tmp_setup_path/sudo_init.sh"
Ubuntu run "$tmp_setup_path/init.sh"

& ..\..\..\..\general_programming_scripting\powershell\vsCode\vsCodeManuallBackup.ps1 -isRestore $true -wsl_command Ubuntu