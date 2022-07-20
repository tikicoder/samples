# Lambda

Lambda Insights uses a CloudWatch Lambda Insights extension. It is only supported on runetimes that support extensions. For more information please refer to the reference section below and goto the Lambda extensions link.

## Permissions

To use CloudWatch Lambda Insights it requires the Lambda to have either the predefined CloudWatchLambdaInsightsExecutionRolePolicy IAM Role or some equivalate custom role.

## Enable

### Console

* Open the Functions page of the Lambda console.
* Choose your function.
* Choose the Configuration tab.
* On the Monitoring tools pane, choose Edit.
* Under Lambda Insights, turn on Enhanced monitoring.
* Choose Save.

### Programmatically - cli

* Ensure the Lambda has proper permissions
  * aws iam attach-role-policy --role-name function-execution-role --policy-arn "arn:aws:iam::aws:policy/CloudWatchLambdaInsightsExecutionRolePolicy"
* Install the Lambda Extension
  * aws lambda update-function-configuration --function-name function-name --layers "arn:aws:lambda:us-west-1:580247275435:layer:LambdaInsightsExtension:14"
* If using a private subnet without internet access
  * Enable CloudWatch Logs VPC endpoint
  * aws ec2 create-vpc-endpoint --vpc-id vpcId --vpc-endpoint-type Interface --service-name com.amazonaws.region.logs --subnet-id subnetId  --security-group-id securitygroupId




## References

* [Using Lambda Insights in Amazon CloudWatch](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-insights.html)
* [Working with Lambda function metrics](https://docs.aws.amazon.com/lambda/latest/dg/monitoring-metrics.html)
* [Lambda runtimes](https://docs.aws.amazon.com/lambda/latest/dg/lambda-runtimes.html)
* [Lambda extensions](https://docs.aws.amazon.com/lambda/latest/dg/runtimes-extensions-api.html)
* [Getting started with Lambda Insights](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-Getting-Started.html)
* [Using the AWS CLI to enable Lambda Insights on an existing Lambda function](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Lambda-Insights-Getting-Started-cli.html)


