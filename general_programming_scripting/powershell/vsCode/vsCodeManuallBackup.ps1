

# vsCodeManuallBackup.ps1 -isRestore $true/$false
# code based on info from
# https://superuser.com/questions/1080682/how-do-i-back-up-my-vs-code-settings-and-list-of-installed-extensions
# There is a new sync setting tool, but this was done so I could easily sync settings from work and personal

param (
    [boolean] $isRestore = $false,
    [string] $pathToVSSettings = "${env:APPDATA}/Code/User/settings.json",
    [string] $pathToVSSettingsBak = "${PSScriptRoot}/settings.bak"
)

if ( $isRestore ) {

    $vsCodeCustomStoreSettings = $(Get-Content $pathToVSSettingsBak | ConvertFrom-Json )

    $vsCodeCustomStoreSettings.extensions | ForEach-Object { code --install-extension $_  }
    $vsCodeCustomStoreSettings.settings | ConvertTo-Json > "${pathToVSSettingsBak}.json"
    Write-Host "Restored to ${pathToVSSettings}"
    exit
}



$vsCodeCustomStoreSettings = New-Object -Type PSObject -Property @{
    'extensions'   = $(code --list-extensions | ConvertTo-Json | ConvertFrom-Json)
    'settings' =  $(Get-Content $pathToVSSettings | ConvertFrom-Json)
}




$vsCodeCustomStoreSettings | ConvertTo-Json > $pathToVSSettingsBak
Write-Host "Backed up to ${pathToVSSettingsBak}"