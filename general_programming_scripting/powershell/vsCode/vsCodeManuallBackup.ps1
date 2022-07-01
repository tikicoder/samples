

# vsCodeManuallBackup.ps1 -isRestore $true/$false
# code based on info from
# https://superuser.com/questions/1080682/how-do-i-back-up-my-vs-code-settings-and-list-of-installed-extensions
# There is a new sync setting tool, but this was done so I could easily sync settings from work and personal

param (
    [boolean] $isRestore = $false,
    [string] $pathToVSSettings = "${env:APPDATA}/Code/User/settings.json",
    [string] $pathToVSSettingsBak = "${PSScriptRoot}/settings.bak",
    [string] $wsl_command = $null,
    [bool] $skip_wsl = $false,
    [bool] $skip_win = $false
)

if ( $isRestore ) {

    $vsCodeCustomStoreSettings = $(Get-Content $pathToVSSettingsBak | ConvertFrom-Json )

    if (-not $skip_win){
        $vsCodeCustomStoreSettings.extensions | ForEach-Object { code --install-extension $_  }
        $vsCodeCustomStoreSettings.settings | ConvertTo-Json > "${pathToVSSettingsBak}.json"
        Write-Host "Restored to ${pathToVSSettings}"
    }

    if ((-not ($null -eq $wsl_command)) -and (-not $skip_wsl )) {
        $vsCodeCustomStoreSettings.extensions | ForEach-Object { 
            $scriptBlock_wsl = [Scriptblock]::Create("wsl -d $($wsl_command) code --install-extension $_")
            Invoke-Command -ScriptBlock $scriptBlock_wsl
        }
    }

    exit
}



$vsCodeCustomStoreSettings = @{
    'extensions'   = $(code --list-extensions | ConvertTo-Json | ConvertFrom-Json)
    'settings' =  $(Get-Content $pathToVSSettings | ConvertFrom-Json)
}

if (-not $null -eq $wsl_command) {
    $scriptBlock_wsl = [Scriptblock]::Create("wsl -d $($wsl_command) code --list-extensions")
    $vsCodeCustomStoreSettings.wsl_extensions =  $( Invoke-Command -ScriptBlock $scriptBlock_wsl) | ConvertTo-Json | ConvertFrom-Json
}


$vsCodeCustomStoreSettings | ConvertTo-Json > $pathToVSSettingsBak
Write-Host "Backed up to ${pathToVSSettingsBak}"