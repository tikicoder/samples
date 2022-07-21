# ift-aws-sm-documents
custom AWS SM Documents that can be run against instances


# to-do
Add linux installer
See if we can run it as python
https://docs.aws.amazon.com/systems-manager/latest/userguide/automation-action-executeScript.html
The plan is to use the python script to get the needed information (could even be done for the windows)
Then it can send to the script to download the data and run it and then the next step revoke the creds. This way the script handels a good portion of the data.

running the following commands on a windows server and restarting the server did have the host regenerate a host id
reg delete "HKLM\SYSTEM\CrowdStrike{9b03c1d9-3138-44ed-9fae-d9f4c034b88d}\{16e0423f-7058-48c9-a204-725362b67639}\Default" /v "AG"
reg delete "HKLM\SYSTEM\CurrentControlSet\Services\CSAgent\Sim" /v "AG"

Other options
create a new sensor update polucy for upgrading/downgrading that will cause it to regen the id

since this is a script probably the better option is uninstall/reinstall


Update so that crowdstrike trys to determine if the host id is for the host you are on 

/devices/queries/devices/v1
"hostname:'WIN-1D10HJUOSK6'+local_ip:'10.109.224.42'+mac_address:'22-00-0a-6d-e0-2a'+device_id:*'*77209ae385b3420dadc8491c0a525b52*'"
The thought is if I can get the devide id I can look it up and then compare hostname, and local ip or mac or both. Thoses should be unique enough to help determine if the server is using a shared id

# references
There is a boto script that can be found at  
/aws_samples/python/samples/run_ssm_automation

That script will help run automation documents on any account using the SSO module

# sample running code
terraform plan --var-file="./variable_data/devops_resources.tfvars"  -out plan.tfplan
terraform apply --auto-approve plan.tfplan

terraform apply --var-file="./variable_data/devops_resources.tfvars" --auto-approve

# Samples

To run the Crowdstrike here is a sample script
The values for the baseapiurl, cid, clientid, and secret can be pulled from the Parameter store on the account 
aws ssm start-automation-execution --profile default --document-name "InstallCrowdstrike" --document-version "\$DEFAULT" --parameters '{"instanceid":["i-00000000000"],"baseapiurl":[""],"cid":[""],"clientid":[""],"secret":[""]}' --region us-east-1