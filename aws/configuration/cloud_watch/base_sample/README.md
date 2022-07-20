# CloudWatch

## Base Sample

https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Metrics-Explorer.html#CloudWatch-Metrics-Explorer-agent
Form the AWS Documentation
To enable metrics explorer to discover EC2 metrics published by the CloudWatch agent, make sure that the CloudWatch agent configuration file contains the following values:

In the metrics section, make sure that the aggregation_dimensions parameter includes [InstanceId"]. It can also contain other dimensions.

In the metrics section, make sure that the append_dimensions parameter includes a {InstanceId":"${aws:InstanceId}"} line. It can also contain other lines.

In the metrics section,inside the metrics_collected section, check the sections for each resource type that you want metrics explorer to discover, such as the cpu, disk, and memory sections. Make sure that each of these sections has a "resources": [ "*"] line.. aggregation_dimensions parameter includes [InstanceId"]. It can also contain other dimensions.

In the cpu section of the metrics_collected> section, make sure there is a "totalcpu": true line.

The settings in the previous list cause the CloudWatch agent to publish aggregate metrics for disks, CPUs, and other reousrces that can be plotted in metrics explorer for all the instances that use it.

These settings will republish the metrics that you had previously set up to be published with multiple dimensions, adding to your metric costs.

To learn more about the settings
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html


## References

* [Manually create or edit the CloudWatch agent configuration file](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)
* [LogLevelType](https://docs.aws.amazon.com/sdk-for-go/api/aws/#LogLevelType)


