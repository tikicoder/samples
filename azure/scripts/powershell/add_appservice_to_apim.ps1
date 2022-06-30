param([string]$RESOURCEGROUPNAMEAPP,[string]$WEBAPPNAME,[string]$RESOURCEGROUPNAME,[string]$APIMSERVICENAME,[string]$APIPATH, [string[]] $VERSIONS)

Function Get-ApiVersionSet
{
    Param ($name, $context)

    $versionSets = Get-AzApiManagementApiVersionSet -Context $context | Where-Object { $_.DisplayName -eq $name }
    if ($versionSets.Length -lt 1) {
        $versionSet = New-AzApiManagementApiVersionSet -Context $context -Name $name -Scheme Query -QueryName api-version
        return $versionSet
    }

    return $versionSets[0]
}

Function Get-Api
{
    Param ($path, $version, $context)

    $apis=Get-AzApiManagementApi -Context $context | Where-Object -Property ApiVersion -EQ -Value $version | Where-Object -Property Path -EQ -Value $path

    if ($null -eq $apis -or $apis.Length -lt 1) {
        return $null
    }

    return $apis[0]
}

Function MoveApiIntoVersionSet 
{
    Param($path, $version, $context, $versionSet)

    $api = Get-Api $path $version $context
    if ($null -ne $api) {
        # ensure old api's are put into version set
        if ($api.ApiVersionSetId -ne $versionSet.Id) {
            $api.ApiVersionSetId = $versionSet.Id
            Set-AzApiManagementApi -InputObject $api
        }

        return $api.ApiId
    }

    return "$path-v" + $version.Replace(".", "-")
}

Function UploadApi
{
    Param($versionSet, $version, $context, $url, $serviceUrl)

    Write-Host "Moving existing API into version set"

    $apiId = MoveApiIntoVersionSet $APIPATH $version $context $versionSet

    Write-Host "Importing API v$version"

    $api = Import-AzApiManagementApi -ApiId $apiId -Context $context -SpecificationFormat "OpenApi" -SpecificationUrl $url -Path $APIPATH -ServiceUrl $serviceUrl -ApiVersionSetId $versionSet.ApiVersionSetId -ApiVersion $version
    Add-AzApiManagementApiToProduct -Context $context -ProductId "starter" -ApiId $api.ApiId
    Add-AzApiManagementApiToProduct -Context $context -ProductId "unlimited" -ApiId $api.ApiId

    # empty version defaults to 1
    if ($version -eq "") {
        $version="1"
    }

    $currentDirectory=[io.path]::GetDirectoryName($MyInvocation.ScriptName)
    $policyPath="$currentDirectory/../apim-policies/v$version/"
    $policiesExist=Test-Path $policyPath
    if ($policiesExist -eq $false) {
        Write-Host "No policies exist for this API"
        return;
    }

    Write-Host "Uploading API Policies"

    $policies=Get-ChildItem -Path $policyPath -Filter "*.xml"
    foreach ($policy in $policies) {
        $operationId=[io.path]::GetFileNameWithoutExtension($policy.Name)

        Write-Host "Uploading API Policy for v$version $operationId"

        Set-AzApiManagementPolicy -Context $context -ApiId $api.ApiId -OperationId $operationId -PolicyFilePath $policy.FullName
    }
}

if ($APIMSERVICENAME.Length -lt 1) {
    Write-Host "##vso[task.logissue type=warning]APIM Service Name is Empty Skipping"
    exit
}

$context = New-AzApiManagementContext -ResourceGroupName $RESOURCEGROUPNAME -ServiceName $APIMSERVICENAME
$versionSet = Get-ApiVersionSet $APIPATH $context
$stagingSite = Get-AzWebAppSlot -ResourceGroupName $RESOURCEGROUPNAMEAPP -Name $WEBAPPNAME -Slot staging
$serviceUrl = "https://$WEBAPPNAME.azurewebsites.net"

foreach ($version in $VERSIONS) {
    $url = "https://$($stagingSite.DefaultHostName)/swagger/v$version/swagger.json"

    # Other API's use the empty version to default to 1, but since 1 is maintained throuugh the
    # ShopWithScrip.ApiManagement Repo for Auth and CRM, we don't do that here.

    # if ($version -eq "1" -or $version -eq "1.0") {
    #     UploadApi $versionSet "" $context $url $serviceUrl
    # }

    # Add Versioned API
    UploadApi $versionSet $version $context $url $serviceUrl
}
