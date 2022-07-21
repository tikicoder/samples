output "params" {
  value = {
    for key in keys(aws_ssm_parameter.ec2ImageBuilderParams):
      key => {
        "arn" = aws_ssm_parameter.ec2ImageBuilderParams[key].arn
        "name" = aws_ssm_parameter.ec2ImageBuilderParams[key].name
        "type" = aws_ssm_parameter.ec2ImageBuilderParams[key].type
        "version" = aws_ssm_parameter.ec2ImageBuilderParams[key].version
      }
      
  }
  sensitive = true
}


