
$scriptPath_init_generalmain = split-path -parent $MyInvocation.MyCommand.Definition

function validate-user-admin-context(){
  
  $currentPrincipal = New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent())
  if(-not $currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){   
    return $false
  }

  return $true
}

$root_path_computer_config = Resolve-Path -Path $(Join-Path -Path $scriptPath_init_generalmain -ChildPath "../../")
$root_path_samples =  Resolve-Path -Path $(Join-Path -Path $root_path_computer_config -ChildPath "../")
$is_admin_context = validate-user-admin-context




function Get-Download-Remote-File()
{
    param (
      [string]$url_remote_file,
      [string]$save_location
    )

    $request  = [System.Net.WebRequest]::Create($url_remote_file)
    $response = [System.Net.HttpWebResponse]$request.GetResponse()
    
    try {
      $dispositionHeader = $response.Headers['Content-Disposition']
      $disposition = [System.Net.Mime.ContentDisposition]::new($dispositionHeader)
      $file_save_name = $disposition.FileName
    }
    catch {
      $file_save_name = ""
    }
    
    if ([string]::IsNullorWhitespace($file_save_name)){
      $file_save_name = $response.ResponseUri.Segments[$response.ResponseUri.Segments.Length-1]
    }

    $filepath = Join-Path -Path $save_location -ChildPath $file_save_name
    if (-not (Test-Path -Path $save_location)) {New-Item -ItemType Directory -Path $save_location}
    if (Test-Path $filepath){Remove-Item -Force -Path $filepath}

    $file = [System.IO.FileStream]::new($filepath, [System.IO.FileMode]::Create)
    $response.GetResponseStream().CopyTo($file);
    $file.Close()

    return $filepath
}

function WaitUntilServices($searchString, $status)
{
    # Get all services where DisplayName matches $searchString and loop through each of them.
    foreach($service in (Get-Service -DisplayName $searchString))
    {
        # Wait for the service to reach the $status or a maximum of 30 seconds
        $service.WaitForStatus($status, '00:00:30')
    }
}

function Ensure-TempDirectory-Populated()
{
  param (
    [string]$Distro,
    [string]$rootPath,
    [string]$wslSharePath,
    [string]$tmpDirectoryPath,
    [string]$scriptPathInitMainset
  )
  
  while(-not (Test-Path -Path "$($wslSharePath)\$Distro$($tmpDirectoryPath)")){
    Write-Host "Directory Missing - Distro: $($Distro) - Path: $( $tmpDirectoryPath)"
    wsl -d $Distro -e mkdir -p "$($tmpDirectoryPath)"
  }
  Write-Host "Directory Exists - Distro: $($Distro) - Path: $( $tmpDirectoryPath)"
 

  Copy-item -Path $(Join-Path -Path $rootPath -ChildPath "general\wsl\scripts\*.sh") -Destination "\\wsl$\$($Distro)$($tmpDirectoryPath)\"

  Copy-item -Path $(Join-Path -Path $scriptPathInitMainset -ChildPath "base_init.sh") -Destination "\\wsl$\$($Distro)$($tmpDirectoryPath)\base_init.sh"
}

function Wait-Distro-Start()
{
  param (
    [string]$Distro
  )
  
  Write-Host "Pending Distro Start - $Distro"
  while ($(wsl -l --running | Where-Object {$_ -ieq $Distro -or $_ -ieq "$Distro (default)"} | Measure-Object).Count -lt 1){
    (wsl -d $Distro -e echo "test") | Out-Null
    Start-Sleep -m 500
  }
  wsl -d $Distro echo "Connected"
}

function Copy-Missing-Certs(){
  param (
    [string]$DestinationTempFolderInDistro,    
    [string]$DestinationSSLFolderInDistro,
    [string]$Distro
  )
  
  $missing_root_certs_path = $(Join-Path -Path $general_defaults.root_path -ChildPath 'general\missing_root_certs' )
  $missing_root_certs = $(Get-Childitem -Path $missing_root_certs_path -File | Where-Object {$_.Name.ToLower().EndsWith(".crt")})

  foreach ( $file in $missing_root_certs){
    Copy-item -Path $file.FullName -Destination $(Join-Path -Path "\\wsl$\$($Distro)$($DestinationTempFolderInDistro)" -ChildPath $file.Name)
    wsl -d $Distro openssl x509 -in "$($DestinationTempFolderInDistro)/$($file.Name)" -out "$($DestinationTempFolderInDistro)/$($file.Name).pem" -outform PEM
    Remove-Item -Force -Path $(Join-Path -Path "\\wsl$\$($Distro)$($DestinationTempFolderInDistro)" -ChildPath $file.Name)
  }

  if ( $missing_root_certs.Length -gt 0 ){
    wsl -d $Distro sudo cp "$($DestinationTempFolderInDistro)/*.pem" $DestinationSSLFolderInDistro
  }
}

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

function Convert-GeneralPsObjectHashTable(){
  param(
    [object]$settings
  )

  $general_settings = @{}
  
  foreach ($property in $settings.PSObject.Properties) {
    if ( $null -ne $property.Value -and $property.Value.GetType().Name -ieq "PSCustomObject"){
      $general_settings[$property.Name] = Convert-GeneralPsObjectHashTable -settings $property.Value
      continue
    }
    $general_settings[$property.Name] = $property.Value
  }

  return $general_settings
  
}

function Load-Settings(){
  param(
    [string] $path_to_settings = $null
  )

  if ( [string]::IsNullorWhitespace($path_to_settings) ){
    return $null
  }


  if ((Test-Path $path_to_settings)) { 
      return Convert-GeneralPsObjectHashTable -settings $(Get-Content -Path $path_to_settings | ConvertFrom-Json)      
  }

  return $null
  
}


$general_defaults = Load-Settings -path_to_settings $(Join-Path -Path $scriptPath_init_generalmain -ChildPath "defaults.json")
$general_defaults.root_path = $(Join-Path -Path $scriptPath_init_generalmain -ChildPath "..\")
$general_defaults.repo_root = $(Join-Path -Path $scriptPath_init_generalmain -ChildPath "..\..\..\")
$general_defaults.main_distro = ""
