
# This is designed to be ran as a c&p (Copy and Paste) script

[int] $AccountExpiresIn_x = 2
[ValidateSet("Days", "Hours", "Minutes")]
[string] $AccountExpiresInType = "Hours"
[string] $AccountUserName = "temp_local_user"
[bool] $IsAdmin = $true
[bool] $DeleteUser = $false
[bool] $DeleteUserConfirm = $true


function Get-RandomPassword {
  param (
      [Parameter(Mandatory)]
      [int] $length,
      [int] $amountOfNonAlphanumeric = 1
  )
  $letters = "abcdefghijklmnopqrstuvwxyz"
  $nonalpha = "#$=%^&*"

  $password = ""

  while ($password.Length -lt $length) {
    $password_letter = $letters[$(Get-Random -Maximum ($letters.length-1) -Minimum 0)]
    if ( ($(Get-Random -Maximum 100 -Minimum 1) % $(Get-Random -Maximum 5 -Minimum 2) ) -eq 0 ){
      $password_letter = $password_letter.ToString().ToUpper() 
    }

    $password = $password + $password_letter  
    
    if ( (($password.Length) -eq ($length - $amountOfNonAlphanumeric) -and $amountOfNonAlphanumeric -gt 0) -or ($amountOfNonAlphanumeric -gt 0 -and ($(Get-Random -Maximum 100 -Minimum 1) % $(Get-Random -Maximum 5 -Minimum 2) ) -eq 0 )){
      if (($password.Length) -eq ($length - $amountOfNonAlphanumeric) -and $amountOfNonAlphanumeric -gt 0 ){
        while ($password.Length -lt $length) {
          $amountOfNonAlphanumeric = $amountOfNonAlphanumeric - 1
          $password = $password + $nonalpha[$(Get-Random -Maximum ($nonalpha.length-1) -Minimum 0)]  
        }
      }
      else {
        $amountOfNonAlphanumeric = $amountOfNonAlphanumeric - 1
        $password = $password + $nonalpha[$(Get-Random -Maximum ($nonalpha.length-1) -Minimum 0)]  
      }
    }
    
  }

  return $password
  
}

if ($DeleteUser) {
  if ((Get-LocalUser | Where-Object {$_.Name -ieq $AccountUserName} | Measure-Object).Count -lt 1){
    Write-Host "$($AccountUserName) does not exist, skipping Delete"
    exit
  }
  Write-Host "This will Delete the following user. This Cannot be reversed."
  Remove-LocalUser -Name $AccountUserName -Confirm:$DeleteUserConfirm
  exit
}

if ((Get-LocalUser | Where-Object {$_.Name -ieq $AccountUserName} | Measure-Object).Count -gt 0){
  
  Write-Host "$($AccountUserName) already Exists"
  exit
}

$TimeSpanParmeters = @{
  $AccountExpiresInType = $AccountExpiresIn_x
}
$AccountExpires = (Get-Date) + (New-TimeSpan @TimeSpanParmeters)

$UserPasswordPlain = (Get-RandomPassword -length 16 -amountOfNonAlphanumeric 2)
$UserPassword = ConvertTo-SecureString -Force -AsPlainText -String $UserPasswordPlain

New-LocalUser `
   -AccountExpires $AccountExpires `
   -Description "Temp User, expires: $($AccountExpires.ToString("yyyyMMddTHH:mm:ss"))" `
   -Name $AccountUserName `
   -Password $UserPassword `
   -Confirm:$false

if ( $IsAdmin ){
  Add-LocalGroupMember -Group “Administrators” -Member $AccountUserName
}

Write-Host "Current DateTime: $(Get-Date)"
Write-Host "Is Admin User: $($IsAdmin)"
Write-Host "User Information:"
$AccountUserName
$UserPasswordPlain
