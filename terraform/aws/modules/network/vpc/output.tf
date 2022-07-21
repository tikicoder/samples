output "vpc" {
  value = try(aws_vpc.aws_VPC[0], null)
}
