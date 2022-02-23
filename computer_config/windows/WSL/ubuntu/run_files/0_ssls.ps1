$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"


$missing_root_certs_path = $(Join-Path -Path $scriptPath_init -ChildPath '..\..\missing_root_certs' )
$missing_root_certs = $(Get-Childitem -Path $missing_root_certs_path -File | Where-Object {$_.Name.ToLower().EndsWith(".crt")})


$files_copy = Get-ChildItem "$($scriptPath_init)/*.sh" -File -Recurse
foreach ( $file in $missing_root_certs){
  Copy-item -Path $file.FullName -Destination "\\wsl$\Ubuntu\usr\local\share\ca-certificates\$($file.Name)"
}


wsl -d Ubuntu update-ca-certificates --fresh
