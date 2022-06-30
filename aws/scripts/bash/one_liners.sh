# Get all instances that do not have the tag aws:autoscaling:groupName and then append the arn to the isntance id and sort
aws ec2 describe-instances --query 'Reservations[].Instances[?!not_null(Tags[?Key == `aws:autoscaling:groupName`].Value)] | [].InstanceId' | jq -r '[.[] | "arn:aws:ec2:us-east-1:<accountid>:instance/"+.] | sort | .[]'

# list all protected resources and filter them to only EC2 and get the ResourceARN which would have the instance id
aws backup list-protected-resources --profile 000000000000 | jq -r '[.Results[] | select(.ResourceType == "EC2").ResourceArn] | sort | .[]'