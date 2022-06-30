function IsNullOrEmptyResourceValue {
    param( 
        [Parameter(Mandatory = $true)][string]$validateString
     )    
    
     if([string]::IsNullOrWhiteSpace($validateString)){
        return $true;
    }

    if($validateString.Trim() -eq "_"){
        return $true;
    }
     
    return $false
}

function SkipDeployment([string]$resourcePREFIX) {
    
    if( [string]::IsNullOrWhiteSpace($resourcePREFIX) ) {
        Write-Host "##vso[task.logissue type=error]Resource_Prefix is not defined"
        return $true;
    }

    if( [string]::IsNullOrWhiteSpace($TERRAFORM_DEPLOYMENT) ) {
        Write-Host "##vso[task.logissue type=error]TERRAFORM_DEPLOYMENT is not defined"
        return $true;
    }


    $Deployment = $($TERRAFORM_DEPLOYMENT | ConvertFrom-Json | Where-Object { $_.key -eq $resourcePREFIX })

    if ( $Deployment -eq $null){
        Write-Host "##vso[task.logissue type=warning]No deployment for ${resourcePREFIX}"
        return $true;
    }

    if ( $Deployment.skipDeployment ){
        Write-Host "##vso[task.logissue type=warning]${resourcePREFIX} Deployment set to skip"
        return $true;
    }

    return $false;
    

}