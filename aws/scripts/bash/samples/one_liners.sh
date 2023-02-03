# Get all instances that do not have the tag aws:autoscaling:groupName and then append the arn to the isntance id and sort
aws ec2 describe-instances --query 'Reservations[].Instances[?!not_null(Tags[?Key == `aws:autoscaling:groupName`].Value)] | [].InstanceId' | jq -r '[.[] | "arn:aws:ec2:us-east-1:<accountid>:instance/"+.] | sort | .[]'

# list all protected resources and filter them to only EC2 and get the ResourceARN which would have the instance id
aws backup list-protected-resources --profile 000000000000 | jq -r '[.Results[] | select(.ResourceType == "EC2").ResourceArn] | sort | .[]'

# Create RDP Port Tunnel SSM
# if plugin is missing https://docs.aws.amazon.com/systems-manager/latest/userguide/session-manager-working-with-install-plugin.html
aws ssm start-session \
  --profile AWS_PROFILE \
  --target INSTANCE_ID \
  --document-name AWS-StartPortForwardingSession \
  --parameters '{"portNumber":["3389"],"localPortNumber":["53389"]}'

# get a list og images that are owned by aaccount
aws ec2 describe-images --owners <account_id_owner> --filters "Name=name,Values=<start_of_name>*" --query 'Images[*].{ImageId: ImageId, Name: Name, CreationDate:CreationDate}'


# delete account from stackset (only way to delete by acct id is cli)
# if the account is suspended or no longer have access --retain-stacks will allow it to remove
aws cloudformation delete-stack-instances --stack-set-name SNSSupport --accounts '["xxxxxxxxxxxx"]' --regions '["us-east-1"]' --operation-preferences FailureToleranceCount=0,MaxConcurrentCount=1 --retain-stacks

# delete account from stackset and delete stacks in that account
aws cloudformation delete-stack-instances --stack-set-name SNSSupport --accounts '["xxxxxxxxxxxx"]' --regions '["us-east-1"]' --operation-preferences FailureToleranceCount=0,MaxConcurrentCount=1 --no-retain-stacks


