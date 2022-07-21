output "subnet" {
  value = aws_subnet.subnet
}

output "internet_gateway" {
  value = aws_internet_gateway.internet_gateway
}

output "nat_gateway" {
  value = aws_nat_gateway.nat_gateway
}