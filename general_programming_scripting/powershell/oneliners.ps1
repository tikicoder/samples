# Easy way to tell if the AD Conenction is broke
Test-ComputerSecureChannel

# A way to try to repair the connection
Test-ComputerSecureChannel -Repair -Credential $domainCredential

# Get AD Computer name
[System.Net.Dns]::GetHostByName($env:computerName)

# Force remove the computer from a domain. This will NOT remove from AD
netdom remove $(hostname) /Force

# Create a Secure String that can be used as part of a Creds object
$ad_passwordSecure = ConvertTo-SecureString -String "..." -AsPlainText -Force

# Creates a creds object for a user/password
$domainCredential = New-Object -TypeName System.Management.Automation.PSCredential -ArgumentList "GRCORP\org_aws_domain_join", $ad_passwordSecure

# Add Computer to AD Domain no OU Path
Add-Computer -DomainName "grcorp.guaranteedrate.ad" -Confirm:$False -Force -Credential $domainCredential

# Add Computer to AD Domain with OU Path
Add-Computer -DomainName "grcorp.guaranteedrate.ad" -Confirm:$False -Force -Credential $domainCredential -OuPath ".." 

# Remove current computer from Domain (Recommended way)
Remove-Computer -ComputerName $(hostname) -UnjoinDomaincredential $domainCredential -Verbose -Force

