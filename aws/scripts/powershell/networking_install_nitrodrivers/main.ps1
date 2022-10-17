
function Remove-Folder()
{
    param (
      [string]$path_to_delete,
      [bool] $Recurse  = $false
    )

    if ( [string]::IsNullorWhitespace($path_to_delete) ){
      return
    }
    
    if ( $Recurse -and (Test-Path $path_to_delete ) -and (Get-Item $path_to_delete) -is [System.IO.DirectoryInfo]){
      Get-ChildItem "$($path_to_delete)/*" -File -Recurse | Remove-Item -Force -Confirm:$False
      Remove-Item -Force -Confirm:$False -Recurse $path_to_delete
    }

    if ((Test-Path $path_to_delete )) { Remove-Item -Path $path_to_delete -Recurse -Force -Confirm:$false  }
}

function Download-Drivers()
{
    param (
      [string]$save_path
    )

    $windows_os_version = (Get-CimInstance Win32_OperatingSystem).version.split(".")
    if ( $windows_os_version[0] -ne 6 ){
      Invoke-WebRequest -URI https://s3.amazonaws.com/ec2-windows-drivers-downloads/ENA/x64/2.4.0/AwsEnaNetworkDriver.zip -OutFile $(Join-Path -Path $save_path -ChildPath "AwsEnaNetworkDriver.zip")
      Invoke-WebRequest -URI https://s3.amazonaws.com/ec2-windows-drivers-downloads/NVMe/1.4.1/AWSNVMe.zip -outfile $(Join-Path -Path $save_path -ChildPath "AWSNVMe.zip")
      return
    }

    Invoke-WebRequest -URI https://s3.amazonaws.com/ec2-windows-drivers-downloads/ENA/x64/2.2.3/AwsEnaNetworkDriver.zip -OutFile $(Join-Path -Path $save_path -ChildPath "AwsEnaNetworkDriver.zip")
    Invoke-WebRequest -URI https://s3.amazonaws.com/ec2-windows-drivers-downloads/NVMe/1.3.2/AWSNVMe.zip -outfile $(Join-Path -Path $save_path -ChildPath "AWSNVMe.zip")
}


$driver_tmp_path = $(Join-Path -Path "$([System.IO.Path]::GetTempPath())" -ChildPath "aws_drivers")
if (-not (Test-Path -Path $driver_tmp_path)) {New-Item -ItemType Directory -Path $driver_tmp_path}


Download-Drivers -save_path $driver_tmp_path

$AwsEnaNetworkDriver_path = $(Join-Path -Path $driver_tmp_path -ChildPath "AwsEnaNetworkDriver")
$AWSNVMe_path = $(Join-Path -Path $driver_tmp_path -ChildPath "AWSNVMe")

if (-not (Test-Path -Path $AwsEnaNetworkDriver_path)) {New-Item -ItemType Directory -Path $AwsEnaNetworkDriver_path}
if (-not (Test-Path -Path $AWSNVMe_path)) {New-Item -ItemType Directory -Path $AWSNVMe_path}


Expand-Archive "$(Join-Path -Path $driver_tmp_path -ChildPath "AwsEnaNetworkDriver.zip")" -DestinationPath $AwsEnaNetworkDriver_path
Expand-Archive "$(Join-Path -Path $driver_tmp_path -ChildPath "AWSNVMe.zip")" -DestinationPath $AWSNVMe

&  "$(Join-Path -Path $AwsEnaNetworkDriver_path -ChildPath "install.ps1")"
&  "$(Join-Path -Path $AWSNVMe -ChildPath "install.ps1")"

Remove-Folder -path_to_delete $driver_tmp_path -Recurse $true
