# This can be copied and pasted into a powershell window on the server
write-host "Downloading new SSM Agent"

$ssm_agent_url = "https://s3.amazonaws.com/ec2-downloads-windows/SSMAgent/latest/windows_amd64/AmazonSSMAgentSetup.exe"

$tmp_download_dir = New-Item -ItemType Directory -Path (Join-Path "$([System.IO.Path]::GetTempPath())" "$([System.Guid]::NewGuid())")
$tmp_installer_path = $(Join-Path "$($tmp_download_dir.FullName)" "SSMAgent_latest.exe")

Invoke-WebRequest `
$ssm_agent_url `
    -OutFile $tmp_installer_path

# # If invoke does not work
# $WebClient = New-Object System.Net.WebClient
# $WebClient.DownloadFile($ssm_agent_url, $tmp_installer_path)

# # IF you need to update ECConfig
# # https://docs.aws.amazon.com/AWSEC2/latest/WindowsGuide/UsingConfig_Install.html
# $ec2Config_latest = "https://s3.amazonaws.com/ec2-downloads-windows/EC2Config/EC2Install.zip"
# $ec2Config_latest_local = $(Join-Path "$($tmp_download_dir.FullName)" "EC2Install.zip")
# $WebClient = New-Object System.Net.WebClient
# $WebClient.DownloadFile($ec2Config_latest, $ec2Config_latest_local)
# $ExtractShell = New-Object -ComObject Shell.Application 
# $ExtractFiles = $ExtractShell.Namespace($ec2Config_latest_local).Items() 
# $ExtractShell.NameSpace($tmp_download_dir.FullName).CopyHere($ExtractFiles) 
Start-Process `
    -FilePath $(Join-Path "$($tmp_download_dir.FullName)" "EC2Install.exe") `
    -ArgumentList "/S" -wait

write-host "Running SSM Agent Installer"
Start-Process -FilePath $tmp_installer_path -ArgumentList "/S" -wait

write-host "Pause to ensure previous script is done"
Start-Sleep -s 2

write-host "Removing installer"
Remove-Item $tmp_download_dir.FullName -Recurse

exit
