# CloudWatch 

## Services that publish to CloudWatch

For a full list of services that publish to CloudWatch use this link
(Services List)[https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/aws-services-cloudwatch-metrics.html]

## Extras

### Grafana Integration

Grafana v6.5.0 and later can be used to contextuallly advance through the CloudWatch console and query a dynamic list of metrics by using wildcards.
https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Grafana-support.html

## Notes

If using something like ansible be aware of filters to ensure proper json formating
https://docs.ansible.com/ansible/latest/user_guide/playbooks_filters.html

## References

* [Collect metrics and logs from Amazon EC2 instances and on-premises servers with the CloudWatch agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/Install-CloudWatch-Agent.html)
* [Basic monitoring and detailed monitoring](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/cloudwatch-metrics-basic-detailed.html)
* [Metrics collected by the CloudWatch agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/metrics-collected-by-CloudWatch-agent.html)
* [Enable enhanced networking with the Elastic Network Adapter (ENA) on Linux instances](https://docs.aws.amazon.com/AWSEC2/latest/UserGuide/enhanced-networking-ena.html)
* [CloudWatch agent configuration for metrics explorer](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Metrics-Explorer.html#CloudWatch-Metrics-Explorer-agent)
* [Manually create or edit the CloudWatch agent configuration file](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-Configuration-File-Details.html)
* [OpenTelemetry support in the CloudWatch agent](https://docs.aws.amazon.com/AmazonCloudWatch/latest/monitoring/CloudWatch-Agent-open-telemetry.html)
* [Amazon CloudWatch Prometheus metrics now generally available](https://aws.amazon.com/blogs/containers/amazon-cloudwatch-prometheus-metrics-ga/)
