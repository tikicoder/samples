$domains = @{
    "sample" = @(
        "sample.local"
        "test.sample.local"
        )
}
    
$scanByDomain = @{}

foreach($environment in $domains.GetEnumerator()){
    $scanByDomain[$environment.Key] = @{}
    foreach($domain in $environment.Value){
        $completedScan = $false
        Write-Output "Processing $($domain)"
        while(-not $completedScan){
            $HTML = $null
            [GC]::Collect()
            try{
                $request = Invoke-WebRequest -Uri "https://www.ssllabs.com/ssltest/analyze.html?d=$($domain)" -UseBasicParsing -Headers @{"User-Agent" = "posterRT"}
                $HTML = New-Object -Com "HTMLFile"
                $HTML.write([ref]$request.Content)
                
                $refreshInput = ($HTML.getElementById("refreshIntervalMillisec"))
                if($null -ine $refreshInput){
                    Write-Output "    Pending...."
                    start-sleep -Milliseconds $refreshInput.value
                    continue
                }
                $completedScan = $true
                $scanByDomain[$environment.Key][$domain] = @{}
            }
            catch{
                Write-Host $_.exception
            }	
        }

        $reportSections = ($HTML.getElementById("multiTable").GetElementsByTagName("tr"))
        $scanByDomain[$environment.Key][$domain]["score"] = @{}
        for($count = 0; $count -lt $reportSections.Length; $count+=1){
            $cells = $reportSections[$count].GetElementsByTagName("td")
            try{
                $serverName = $cells[1].GetElementsByTagName("a")[0].innerText
                if([string]::IsNullOrWhiteSpace($serverName) -or ($serverName -ieq "server")){
                    continue
                }
            }
            catch{
                continue
            }			
            $scanByDomain[$environment.Key][$domain]["score"][$cells[1].GetElementsByTagName("a")[0].innerText] = 
            $cells[$cells.length-1].getElementsByClassName("percentage_g")[0].innerText
        }
        start-sleep -seconds (Get-Random -Maximum 6 -Minimum 2)
    }
}
$scanByDomain | ConvertTo-Json -Depth 10 | Out-File -Path (Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "qualys.json")

(Join-Path -Path ([System.IO.Path]::GetTempPath()) -ChildPath "qualys.json")