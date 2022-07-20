# CloudWatch

EC2 Instances need a role with the policy CloudWatchAgentServerPolicy 
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-iam-roles-for-cloudwatch-agent.html


Notes
If using something like ansible be aware of filters to ensure proper json formating
https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters.html