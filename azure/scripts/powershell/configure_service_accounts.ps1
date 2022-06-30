# Use this script to create service accounts for Terraform (per environment)

$envs = @("dev","stage","prod")

foreach ($env in $envs) {
  $sp = New-AzADServicePrincipal -DisplayName terraform-sa-$env
  $BSTR = [System.Runtime.InteropServices.Marshal]::SecureStringToBSTR($sp.Secret)
  $UnsecureSecret = [System.Runtime.InteropServices.Marshal]::PtrToStringAuto($BSTR)
  $appId = Get-AzADServicePrincipal -DisplayName "terraform-sa-$env" | ConvertTo-JSON | jq -r '.[].ApplicationId'
  New-AzRoleAssignment -ApplicationId $appId -RoleDefinitionName "Contributor"

  Write-Host "terraform-sa-$env ID: $appId"
  Write-Host "terraform-sa-$env secret: $UnsecureSecret"
}
