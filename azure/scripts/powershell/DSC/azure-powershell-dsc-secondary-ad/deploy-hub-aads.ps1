#deploy-hub-aads.ps1 "<ResourceGroupName>" "<StorageAccountName>" "<STORAGECONTAINERNAME>" "<LOCATION>" "<dcAdminUserName>" "<dcADminPassword>"

#sample, but please do not use the username and password
#deploy-hub-aads.ps1 "rg-hub-aads" "dscFileStorage" "dsc" "westus2" "admin" "P@ssword!"

param(
    [string]$RESOURCEGROUPNAME,
    [string]$STORAGEACCOUNTNAME,
    [string]$STORAGECONTAINERNAME,
    [string]$LOCATION,
    [string]$dcAdminUserName,
    [string]$dcADminPassword
)

function InstallMissingModule ([string]$ModuleName = "")
{
    if( $ModuleName.Length -lt 1 ){
        Write-Host "No Module"
        exit
    }
    if (Get-Module -ListAvailable -Name $ModuleName) {
        Write-Host "$ModuleName Already Installed"
    } 
    else {
        try {
            Install-Module -Name $ModuleName -AllowClobber -Confirm:$False -Force -Scope CurrentUser
        }
        catch [Exception] {
            $_.message 
            exit
        }
    }
}

Write-Host "Checking for required modules"
$neededModules = @("xActiveDirectory", "xAdcsDeployment", "xDisk", "xNetworking", "xPendingReboot", "xStorage")
foreach ($module in $neededModules) {
    InstallMissingModule $module
}


Write-Host "Starting DSC prep"
$dscFilePath = 'dsc\adds\azure.ps1'
$dscZipFilePath = 'dsc\adds\azure-ad-dsc.zip'
$dscZipFileBlobPath = 'aads/azure-ad-dsc.zip'

Write-Host "Creating Zip"
Publish-AzVMDscConfiguration $dscFilePath -OutputArchivePath $dscZipFilePath -Force
$StorageAccount = Get-AzStorageAccount -Name $STORAGEACCOUNTNAME -ResourceGroupName $RESOURCEGROUPNAME


$Container = $StorageAccount | Get-AzStorageContainer -Name $STORAGECONTAINERNAME

Write-Host "Uploading Zip"
$Container | Set-AzStorageBlobContent -File $dscZipFilePath -Blob $dscZipFileBlobPath -Force

Write-Host "Getting sasToken"
$start = [System.DateTime]::Now.ToUniversalTime().AddHours(-1)
$end = [System.DateTime]::Now.ToUniversalTime().AddHours(2)
$context = (Get-AzStorageAccount -ResourceGroupName $RESOURCEGROUPNAME -AccountName $STORAGEACCOUNTNAME).context
$sasToken = New-AzStorageAccountSASToken -Context $context `
    -Service Blob `
    -ResourceType Service,Container,Object `
    -Permission r `
    -StartTime  $start `
    -ExpiryTime $end

Write-Host "Got sasToken"
$templateFile = "templates/deploy-hub-aads.json"
$parameterFile = "parameters/deploy-hub-aads.parameters.json"
New-AzResourceGroupDeployment  -Name "Deployment.AADS.VM" `
    -TemplateFile $templateFile `
    -ResourceGroupName $RESOURCEGROUPNAME `
    -TemplateParameterFile $parameterFile `
    -storageAccountSasToken $sasToken -Verbose `
    -storageAccountName $STORAGEACCOUNTNAME `
    -setupScriptContainerName $STORAGECONTAINERNAME `
    -iisDSCSetupArchiveFileName $dscZipFileBlobPath `
    -dcAdminUserName $dcAdminUserName `
    -dcADminPassword $dcADminPassword `
