# EC2 

## Important Callouts

* If you set this value below 60 seconds, each metric is collected as a high-resolution metric. For more information about high-resolution metrics, see [High-resolution metrics.](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/publishingMetrics.html#high-resolution-metrics)

* CloudWatch agent supports multiple configuration files, [more information](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-common-scenarios.html#CloudWatch-Agent-multiple-config-files)

* Cloudwatch Agent can be intalled using SSM also that can be used in a state association. [Download and configure the CloudWatch agent
](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/download-CloudWatch-Agent-on-EC2-Instance-SSM-first.html)

## Permissions

Instances need a role with the policy CloudWatchAgentServerPolicy 
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-iam-roles-for-cloudwatch-agent.html

To publish OpenTelemetry metrics and traces the CloudWatch Agent needs extra permissions. The existing default IAM Role is CloudWatchAgentServerRole. 
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-open-telemetry.html

# Recommendations 

The metrics section has the attribute "endpoint_override". It is something that should be considered as it would allow you to use AWS PrivateLink. 
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html

You can use the individual append_dimensions attributes to add custom dimensions.

* "Environment": "prod"

# Reminders

IF you are using the main append_dimensions under the metrics attribute. The hostname is not sent.

Each metrics type can have its own custom metrics_collection_interval.

If you change the config you have to restart the agent.

* Linux
  * nvidia_gpu
    * Optional - Only valid on instances with a NVIDIA GPU
    * (Collect NVIDIA GPU metrics)[https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-NVIDIA-GPU.html]
  * collectd 
    * Optional - You can use this to configure custom metrics
    * (Retrieve custom metrics with collectd)[https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-custom-metrics-collectd.html]
  * ethtool 
    * Optional - You can receive network metrics using this plugin
    * (Collect network performance metrics)[https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-network-performance.html]
* Windows
  * statsd 
    * Optional - You can use this to configure custom metrics
    * (Retrieve custom metrics with StatsD)[https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-custom-metrics-statsd.html]
  * procstat  
    * Optional - You can receive metrics from individual processes
    * (Collect process metrics with the procstat plugin)[https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-procstat-process-metrics.html] 

You can use Multiple agent configuration files


#### Save Configuration

Manually
* Linux 
  * /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json
* Windows
  * $Env:ProgramData\Amazon\AmazonCloudWatchAgent\amazon-cloudwatch-agent.json

SSM Parameter Store

* Requires IAM Role to store it
* EC2 requires permissions to pull it
* command
  * aws ssm put-parameter --name "parameter name" --type "String" --value file://configuration_file_pathname




#### Commands 

Update local config on EC2
sudo /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl -m ec2 -a fetch-config -c file:/path/to/file.json -s

## Prometheus

Setup CW Agent to scrap Prometheus
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-PrometheusEC2.html#CloudWatch-Agent-PrometheusEC2-configure

## References

* (Windows Performance Counters)[https://docs.microsoft.com/en-us/azure/azure-monitor/agents/data-sources-performance-counters]
* [Collect metrics and logs from Amazon EC2 instances and on-premises servers with the CloudWatch agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
* [Create the CloudWatch agent configuration file](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/create-cloudwatch-agent-configuration-file.html)


