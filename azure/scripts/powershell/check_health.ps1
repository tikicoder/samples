param([string]$ResourceGroup,[string]$AppName, [string]$IP_ADDRESS)

$stagingSite = Get-AzWebAppSlot -ResourceGroupName $ResourceGroup -Name $AppName -Slot staging
$url = "https://$($stagingSite.DefaultHostName)/health"

$scriptIPNAME = "Check Health Temp"

Function Remove-IP-Access
{
    if ( -NOT $ipRestrictionAdded){
        return;
    }

    Write-Host "Removing temp IP of ${IP_ADDRESS_SCRIPT}"
    Remove-AzWebAppAccessRestrictionRule -ResourceGroupName "$ResourceGroup" -WebAppName "$AppName" `
        -Name "${scriptIPNAME}" `
        -SlotName staging
}

Function Add-IP-Access
{

    Write-Host "##vso[task.logissue type=warning]Current Host IP: ${IP_ADDRESS_SCRIPT}  Global Host IP: ${IP_ADDRESS}"

    Write-Host "Adding temp IP of ${IP_ADDRESS_SCRIPT}"
    Add-AzWebAppAccessRestrictionRule -ResourceGroupName "$ResourceGroup" -WebAppName "$AppName" `
        -Name "${scriptIPNAME}" -Priority 150 -Action Allow -IpAddress "${IP_ADDRESS_SCRIPT}/32" `
        -SlotName staging
}

Function Site-Healthy
{
    Param (
        [string]$url,
        [int]$attempt,
        [bool]$restart,
        [bool]$ipRestrictionAdded
        )
    
    if ( -NOT $ipRestrictionAdded -and (-NOT (( $IP_ADDRESS -eq $IP_ADDRESS_SCRIPT))) ){
        Add-IP-Access
        $ipRestrictionAdded = $true
    }

    
    $retryInterval = 10
    $attempt = $attempt + 1
    Write-Host "Checking Health"
    Write-Host "Attempt: ${attempt}"
    
    
    $health = try { (Invoke-RestMethod -Uri $Url -Method GET) } catch { $_.Exception.Response }
    if ($health -eq "Healthy") {
        Remove-IP-Access
        return $true
    }

    Write-Host "##vso[task.logissue type=warning]API is not Healthy. Current status is $($health.ReasonPhrase)"
    
    if ( ($health.StatusCode -eq 403) -AND ($ipRestrictionAdded -eq $false) ) {
        Add-IP-Access
    }

    if( $restart ){
        Write-Host "Restarting Service"
        $appRestart = $(Restart-AzWebAppSlot -ResourceGroupName "$ResourceGroup" -Name "$AppName" -Slot staging)

        if( $appRestart.State -eq "Stopped"){
            Start-AzWebAppSlot -ResourceGroupName $ResourceGroup -Name $AppName -Slot staging
        }
    }

    if( $attempt -lt 6){
        Write-Host "Pausing ${retryInterval} seconds for service to start"
        Start-Sleep -Seconds $retryInterval
        return $(Site-Healthy $url $attempt $false $true)
    }

    Remove-IP-Access
    Write-Host "API is not Healthy. Current status is ${health}"
    return $false;   
}

$IP_ADDRESS_SCRIPT = (Invoke-WebRequest -uri "http://ifconfig.me/ip").Content
if( -NOT $(Site-Healthy $url 0 $true $false)){
    exit 1;
}

Write-Host "API is Healthy"