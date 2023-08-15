
function run-windows { 

  $docker_Version = "docker-24.0.5.zip"
  $docker_storage_dir = "C:\ProgramData\docker"
  $docker_install_path = "C:\docker"
  
  if ( $(Get-Service | Where-Object {$_.Name -ieq "docker"} | Measure-Object).Count -gt 0 ){
    Stop-Service docker

    $(Get-Service docker).WaitForStatus('Stopped')
    if ((Test-Path -Path $docker_install_path)) {
      & C:\docker\dockerd --unregister-service
    }
  }
  
  if ((Test-Path -Path $docker_install_path)) {Remove-Folder -path_to_delete $docker_install_path -Recurse $true}
  try {
    if ((Test-Path -Path $docker_storage_dir)) {Remove-Folder -path_to_delete $docker_storage_dir -Recurse $true}
  }
  catch {
    if (Test-Path -Path $docker_storage_dir) { takeown.exe /F $docker_storage_dir /R /A /D Y }
    if (Test-Path -Path $docker_storage_dir) { icacls "$($docker_storage_dir)\" /T /C /grant Administrators:F }
    if ((Test-Path -Path $docker_storage_dir)) {Remove-Folder -path_to_delete $docker_storage_dir -Recurse $true}
    if ((Test-Path -Path "$($docker_storage_dir)\config")) {Remove-Folder -path_to_delete "$($docker_storage_dir)\config" -Recurse $true}
  }

  if ((Test-Path -Path "$($docker_storage_dir)\config")) {
    Write-Host "Existing Docker Config still exists"
  }

  $tmp_dir_docker = (Join-Path -Path "$([System.IO.Path]::GetTempPath())" -ChildPath "win_docker")
  if (-not (Test-Path -Path $tmp_dir_docker)) {New-Item -ItemType Directory -Path $tmp_dir_docker}


  $tmp_docker_save = $(Join-Path -Path $tmp_dir_docker -ChildPath $docker_Version )
  Write-Host  "Downloading $docker_Version and saving to $tmp_dir_docker"

  $tmp_docker_save = $(Get-Download-Remote-File `
    -url_remote_file "https://download.docker.com/win/static/stable/x86_64/$docker_Version" `
    -save_location $tmp_dir_docker)

  Expand-Archive $tmp_docker_save -DestinationPath C:\ -Force
  $existing__environment_paths = $($env:path).Split(";", [System.StringSplitOptions]::RemoveEmptyEntries)
  if( ($docker_install_path -inotin  $existing__environment_paths) -and ("$($docker_install_path)\" -inotin  $existing__environment_paths)){
    [Environment]::SetEnvironmentVariable("Path", "$($env:path);C:\docker", [System.EnvironmentVariableTarget]::Machine)
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
  }

  dockerd --register-service
  Start-Service docker
  if(-not $?){
    Write-Host "Running as Admin"
    start-process -verb runas -ArgumentList "-Command Start-Service docker" pwsh
  }
  
  WaitUntilServices "Docker Engine" "Running"

  if (-not (Test-Path -Path "$($docker_storage_dir)\config")) {
    if (Test-Path -Path $docker_storage_dir) { 
      New-Item -ItemType Directory -Path $docker_storage_dir
    }
    # Doc for more config settings
    # https://learn.microsoft.com/en-us/virtualization/windowscontainers/manage-docker/configure-docker-daemon
    New-Item -ItemType Directory -Path "$($docker_storage_dir)\config"
    Copy-Item -Force -Path $(Join-Path -Path $scriptPath_init -ChildPath "..\general\docker\daemon.json") -Destination "$($docker_storage_dir)\config\daemon.json"
    Stop-Service docker
    WaitUntilServices "Docker Engine" "Stopped"
    
    Start-Service docker
    WaitUntilServices "Docker Engine" "Running"
  }

  Remove-Item -Force -Confirm:$False -Recurse $tmp_dir_docker
}
