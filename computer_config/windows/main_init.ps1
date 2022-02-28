$scriptPath_init_mainset = split-path -parent $MyInvocation.MyCommand.Definition

$run_files_dir = Join-Path -Path $scriptPath_init_mainset -ChildPath "run_files"
$run_files = Get-ChildItem "$($run_files_dir)/*.ps1" -File | Sort-Object -Property Name

Write-host "If you are running ZScaler Please disable it now to ensure no issues"
pause

foreach ( $file in $run_files){
  Write-Host "Running $($file.Name)"
  & $file.FullName
}