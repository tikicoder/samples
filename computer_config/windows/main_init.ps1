$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

$run_files_dir = Join-Path -Path $scriptPath_init -ChildPath "run_files"
$run_files = Get-ChildItem "$($run_files_dir)/*.ps1" -File | Sort-Object -Property Name

foreach ( $file in $run_files){
  Write-Host "Running $($file.Name)"
  & $file.FullName
}