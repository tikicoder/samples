# SSM Trouble Shooting

## If you install/update SSM on windows and it shows connected but you are unable to connect
### possible error
Plugin with name Standard_Stream is not supported in current platform. Step name: Standard_Stream

Fix
connect via RDP and open PowerShell
run the following commend

Test-Path -Path 'C:\Windows\System32\wbem\WMIC.exe';

If that returns false the WMIC.exe is missing, if true you can skip theses steps
* spin up a new instance with the same version of the OS
* zip up the folder C:\Windows\System32\wbem and download it to your machine
* copy it to the previous instance and unzip it at C:\Windows\System32\


using the above PowerShell run

$Env:Path

That will list the environment paths

Look to see if the following is listed
%SystemRoot%\System32\Wbem;

If it is not listed that is the problem if it is listed ensure it not something similar to
"%SystemRoot%;%SystemRoot%\System32\Wbem;"
With the quotes it is not the correct path

If its not there you can add it through various methods.
https://helpdeskgeek.com/windows-10/add-windows-path-environment-variable/
https://www.computerperformance.co.uk/powershell/env-path/

I had to do the registry edit, it already existed and was malformed.
I ran the following command in PowerShell to verify that the update happened
[System.Environment]::GetEnvironmentVariable("Path","Machine")

If the path looks correct you can then run in PowerShell
$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine") + ";" + [System.Environment]::GetEnvironmentVariable("Path","User") 
Stop-Service -Name "AmazonSSMAgent"
Start-Service -Name "AmazonSSMAgent"

If everything worked out you should now be able to connect via SSM on the windows Machine
