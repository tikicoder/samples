$scriptPath_init = split-path -parent $MyInvocation.MyCommand.Definition
. "$(Join-Path -Path $scriptPath_init -ChildPath "..\general\defaults.ps1")"


function install-app-winget(){
  param(
    [string]$app_name
  )

  write-host "Installing - $($app_name)"

  if([string]::IsNullOrWhiteSpace($($(winget upgrade -e --id $app_name).trim().tolower() -match "no installed package found"))) {
    write-host "$app_name already installed"
    return
  }

  write-host "$app_name Installing"
  winget install -e --id $app_name
}

function install-latest-dotnet(){

  write-host "Getting - Latest .NET SDK"
  try{
    $version_sdks = $($(winget search --id Microsoft.dotnet) | ForEach-Object {$_.split("  ") | Where-Object {-not [string]::IsNullOrWhiteSpace($_)} | ForEach-Object{$_.trim()}} | Where-Object {$_ -match "microsoft`.dotnet`.sdk(.*)" -and $_ -notmatch "(.*)`.preview"} | Sort-Object -Descending)
  
    write-host "Installing - Latest .NET SDK: $($version_sdks[0])"

    if (-not [string]::IsNullOrWhiteSpace($version_sdks[0])){
      install-app-winget $version_sdks[0]
    }
	
	if ( $($version_sdks | Measure-Object).Count -gt 1 ) {
		write-host "Ensure LTS installed"
		write-host "Installing - Previous .NET SDK: $($version_sdks[1])"
		if (-not [string]::IsNullOrWhiteSpace($version_sdks[1])){
		  install-app-winget $version_sdks[1]
		}
	}
    return
  }
  catch {
    
  }

  write-host "Unable to find latest .net version"
  
}

install-app-winget -app_name "Microsoft.dotNetFramework"

install-latest-dotnet

install-app-winget -app_name "7zip.7zip"

install-app-winget -app_name "WiresharkFoundation.Wireshark"

install-app-winget -app_name "PuTTY.PuTTY"

install-app-winget -app_name "Microsoft.VisualStudioCode"

install-app-winget -app_name "Microsoft.PowerShell"

install-app-winget -app_name "Microsoft.Edge"

install-app-winget -app_name "Microsoft.WindowsTerminal"

install-app-winget -app_name "IrfanSkiljan.IrfanView"

# Atom has been sunsetted and is now in archive mode
# https://github.blog/2022-06-08-sunsetting-atom/
# https://github.com/atom
# https://github.com/atom/atom
# install-app-winget -app_name "GitHub.Atom"

# WSLg support this will be installed on wslG
# install-app-winget -app_name "GIMP.GIMP"

# Ran into some issues on WSLg installing normally
install-app-winget -app_name "OBSProject.OBSStudio"

install-app-winget -app_name "Google.Chrome"

install-app-winget -app_name "Mozilla.Firefox.DeveloperEdition"

install-app-winget -app_name "SlackTechnologies.Slack"

install-app-winget -app_name "Postman.Postman"

install-app-winget -app_name "Microsoft.AzureCLI"

install-app-winget -app_name "Microsoft.AzureStorageExplorer"

install-app-winget -app_name "Python.Python.3.11"

pwsh -Command "Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force"
pwsh -Command "Install-Module -Name PowerStig -Scope CurrentUser -Force"

powershell -Command "Install-PackageProvider -Name NuGet -MinimumVersion 2.8.5.201 -Force"
powershell -Command "Install-Module -Name Az -Scope CurrentUser -Repository PSGallery -Force"

winget upgrade --all

#refresh Env Path
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 

# Import base Widgets (This include the one for WSL)
Write-Host "If widgets fail with `"unable to get local issuer certificate`" please ensure services like zscaler is off"
& "$(Join-Path -Path $root_path_samples -ChildPath "general_programming_scripting\powershell\vsCode\main.ps1")" -isRestore $true -skip_wsl $true 
