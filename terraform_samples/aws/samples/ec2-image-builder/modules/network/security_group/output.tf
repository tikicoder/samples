output "securityGroups_byvpcgroup" {
  value = {
    for key in keys(local.keys): 
      key => {
        for sgKey in keys(aws_security_group.ec2ImageBuilder_SecurityGroups): 
          sgKey=>aws_security_group.ec2ImageBuilder_SecurityGroups[sgKey]
        if substr(sgKey, 0, length(key)+1) == "${key}:"
      }
  }
}


output "securityGroups" {
  value = aws_security_group.ec2ImageBuilder_SecurityGroups
}