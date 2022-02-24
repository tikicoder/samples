$scriptPath_init_generalmain = split-path -parent $MyInvocation.MyCommand.Definition

function Remove-Folder()
{
    param (
      [string]$path_to_delete,
      [bool] $Recurse  = $false
    )
    
    if ( $Recurse -and (Test-Path $path_to_delete ) ){
      Get-ChildItem "$($path_to_delete)/*" -File -Recurse | Remove-Item -Force -Confirm:$False
      Remove-Item -Force -Confirm:$False -Recurse $path_to_delete
    }

    if ((Test-Path $path_to_delete )) { Remove-Item -Path $path_to_delete -Recurse -Force -Confirm:$False  }
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