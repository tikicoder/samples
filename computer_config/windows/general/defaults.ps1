$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition

$general_defaults = Load-Settings -path_to_settings $(Join-Path -Path $scriptPath_init -ChildPath "defaults.json")
$general_defaults.root_path = $(Join-Path -Path $scriptPath_init -ChildPath "..\")

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