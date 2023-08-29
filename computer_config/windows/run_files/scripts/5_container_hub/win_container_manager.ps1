
function run-windows { 
  $winget_dockercli = "Docker.DockerCLI"
  $install_dockercli_winget = $True
  $docker_Version = "docker-24.0.5.zip"
  $docker_storage_dir = "C:\ProgramData\docker"
  $docker_install_path = Join-Path -Path $Env:Programfiles -ChildPath "docker_winget"
  $docker_env_path = Join-Path -Path $Env:Programfiles -ChildPath "docker_winget/docker"
  
  
  winget search --query $winget_dockercli |ForEach-Object { if($_ -ilike "No package *"){
    $install_dockercli_winget = $False
    break
  }}
 
  if ( $((Get-Service  2>$null) | Where-Object {$_.Name -ieq "docker"} | Measure-Object).Count -gt 0 ){
    Stop-Service docker

    $(Get-Service docker).WaitForStatus('Stopped')
    if ((Test-Path -Path $docker_env_path)) {
      & "$($docker_env_path)\dockerd" --unregister-service
    }
  }

  $existing__environment_paths = [System.Collections.Generic.List[String]]$($env:path).Split(";", [System.StringSplitOptions]::RemoveEmptyEntries)
  if(($docker_env_path -iin  $existing__environment_paths) -or ("$($docker_env_path)\" -iin  $existing__environment_paths)){
    $docker_env_index = 0
    while( ($docker_env_path -iin  $existing__environment_paths) -or ("$($docker_env_path)\" -iin  $existing__environment_paths)){
      if($docker_env_path -ieq $existing__environment_paths[$docker_env_index] -or 
        "$($docker_env_path)\" -ieq $existing__environment_paths[$docker_env_index] -or 
        $existing__environment_paths[$docker_env_index] -ilike "$($docker_env_path)\*"){
          $existing__environment_paths.removeAt($docker_env_index)
          continue
        }

        $docker_env_index += 1
    }
    [Environment]::SetEnvironmentVariable("Path", "$($existing__environment_paths -join ";");", [System.EnvironmentVariableTarget]::Machine)
    $env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
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
  
  if($install_dockercli_winget)
  {
    if (-not (Test-Path -Path "$docker_install_path ")) {
      winget uninstall -e --id $winget_dockercli
    }

    winget install -e --id $winget_dockercli -l $docker_install_path 
  }
  else
  {
    $tmp_dir_docker = (Join-Path -Path "$([System.IO.Path]::GetTempPath())" -ChildPath "win_docker")
    if (-not (Test-Path -Path $tmp_dir_docker)) {New-Item -ItemType Directory -Path $tmp_dir_docker}


    $tmp_docker_save = $(Join-Path -Path $tmp_dir_docker -ChildPath $docker_Version )
    Write-Host  "Downloading $docker_Version and saving to $tmp_dir_docker"

    $tmp_docker_save = $(Get-Download-Remote-File `
      -url_remote_file "https://download.docker.com/win/static/stable/x86_64/$docker_Version" `
      -save_location $tmp_dir_docker)

    Expand-Archive $tmp_docker_save -DestinationPath C:\ -Force

    if ((Test-Path -Path $tmp_dir_docker)) {
      Remove-Item -Force -Confirm:$False -Recurse $tmp_dir_docker
    }
  }

  $existing__environment_paths = [System.Collections.Generic.List[String]]$($env:path).Split(";", [System.StringSplitOptions]::RemoveEmptyEntries)
  if( ($docker_env_path -inotin  $existing__environment_paths) -and ("$($docker_env_path)\" -inotin  $existing__environment_paths)){
    [Environment]::SetEnvironmentVariable("Path", "$($env:path);$($docker_env_path)", [System.EnvironmentVariableTarget]::Machine)
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
    if (-not (Test-Path -Path $docker_storage_dir)) { 
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

  docker context create lin --docker host=$($general_defaults.docker.host_tcp)
}
