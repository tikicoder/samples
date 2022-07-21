output "security_group" {
  value = try(aws_security_group.security_group[0], null)
}