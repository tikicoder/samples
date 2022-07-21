output "subnets_byvpcgroup" {
  value = {
    for key in keys(local.keys): 
      key => {
        for rtKey in keys(aws_subnet.ec2ImageBuilder_Subnet): 
          rtKey=>aws_subnet.ec2ImageBuilder_Subnet[rtKey]
        if substr(rtKey, 0, length(key)+1) == "${key}:"
      }
  }
}

output "subnets" {
  value = aws_subnet.ec2ImageBuilder_Subnet
}

output "inetgateway" {
  value = aws_internet_gateway.ec2ImageBuilder_InternetGateway
}

output "netgateway" {
  value = aws_nat_gateway.ec2ImageBuilder_NatGateway
}