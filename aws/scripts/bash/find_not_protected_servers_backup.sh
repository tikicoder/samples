ec2_list=$(aws ec2 describe-instances --profile 000000000000  --query 'Reservations[].Instances[].[Tags[?Key==`aws:autoscaling:groupName`].Value|[0],InstanceId]' | jq -r '[ .[] | select(.[0] == null) | .[1] ] ')

backup_list=$(aws backup list-protected-resources --profile 000000000000 | jq -r '.Results | [.[] | select(.LastBackupTime == "2022-01-17T22:00:00-07:00" and .ResourceType == "EC2") | .ResourceArn | split("/")[1]] ')

echo "{\"ec2_list\":$ec2_list, \"backup_list\":${backup_list}}" | jq -r '.ec2_list-.backup_list'