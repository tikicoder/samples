$domains = @{
    "sample" = @(
        "sample.local"
        "sample.local/test/index.htm"
        )
    }
    
    $scanByDomain = @{}
    $meaderDataTypes = @{
        "missing headers" = "missing"
        "warnings" = "warning"
        "raw headers" = "raw"
        "upcoming headers" = "upcoming"
        "additional information" = "info"
    }
    foreach($environment in $domains.GetEnumerator()){
    $scanByDomain[$environment.Key] = @{}
    foreach($domain in $environment.Value){
    $HTML = $null
    [GC]::Collect()
    
    Write-Output "Processing $($domain)"
    try{
        $request = Invoke-WebRequest -Uri "https://securityheaders.com/?q=$($domain)&hide=on&followRedirects=on" -UseBasicParsing -Headers @{"User-Agent" = "posterRT"}
        [string]$htmlBody = $request.Content
        $HTML = New-Object -Com "HTMLFile"
        $HTML.write([ref]$htmlBody)
        $scanByDomain[$environment.Key][$domain] = @{"headerDetails"=@{}}
    }
    catch{
        Write-Host $_.exception
    }
    
    
    
    $reportSections = ($HTML.getElementsByClassName("reportSection") | Where-Object {$_.localName -ieq "div"})
    $scanByDomain[$environment.Key][$domain]["score"] = (($reportSections[0]).getElementsByClassName("score")[0].GetElementsByTagName('span')[0].innerHtml)
    
    
    foreach($section in $reportSections){
        $sectionHeader = ($section.getElementsByClassName("reportTitle")[0].innerText)
        if($null -ieq $meaderDataTypes[$sectionHeader.ToLower()]){
            continue
        }
        $scanByDomain[$environment.Key][$domain]["headerDetails"][$meaderDataTypes[$sectionHeader.ToLower()]] = @{}
        $missingHeadersHeaders = $section.getElementsByClassName("reportTable")[0].GetElementsByTagName("th")
        $missingHeadersDetails = $section.getElementsByClassName("reportTable")[0].GetElementsByTagName("td")
        for($count = 0; $count -lt $missingHeadersHeaders.Length; $count+=1){
            $scanByDomain[$environment.Key][$domain]["headerDetails"][$meaderDataTypes[$sectionHeader.ToLower()]][$missingHeadersHeaders[$count].innerText] = $missingHeadersDetails[$count].innerText
        }
        
        
    }
    
    
        
        
    start-sleep -seconds (Get-Random -Maximum 6 -Minimum 2)
    }
    }
    $scanByDomain | ConvertTo-Json -Depth 10 | Out-File -Path (Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "securityheaders.json")
    
    (Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "securityheaders.json")