
# https://download.docker.com/win/static/stable/x86_64/
# https://lippertmarkus.com/2021/09/04/containers-without-docker-desktop/

$docker_Version = "docker-20.10.9.zip"
$tmp_dir = (Join-Path "$([System.IO.Path]::GetTempPath())" "win_docker")
if (-not (Test-Path -Path $tmp_dir)) {New-Item -ItemType Directory -Path $tmp_dir}
$webClient = [System.Net.WebClient]::new()
$webClient.DownloadFile("https://download.docker.com/win/static/stable/x86_64/$docker_Version ", $(Join-Path -Path $tmp_dir -ChilePath $docker_Version  ))



Expand-Archive $(Join-Path -Path $tmp_dir -ChilePath $docker_Version  ) -DestinationPath C:\
[Environment]::SetEnvironmentVariable("Path", "$($env:path);C:\docker", [System.EnvironmentVariableTarget]::Machine)
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
dockerd --register-service
Start-Service docker

Remove-Item -Force -Confirm:$False -Recurse $tmp_dir
