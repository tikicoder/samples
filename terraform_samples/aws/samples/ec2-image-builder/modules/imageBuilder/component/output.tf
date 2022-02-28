locals {
  componentArnNoVersionSplit = distinct(flatten([
    for key in keys(aws_imagebuilder_component.ec2ImageBuilder_component) : {
        "key" = substr(key, 0, length(key) - length(aws_imagebuilder_component.ec2ImageBuilder_component[key].version) - 1)
        "componentSplit" = split("/", aws_imagebuilder_component.ec2ImageBuilder_component[key].arn)
      }
  ]))

  componentArnNoVersion = distinct(flatten([
    for item in local.componentArnNoVersionSplit : {
        "key" = item.key
        "componentArn" = "${item.componentSplit[0]}/${item.componentSplit[1]}/x.x.x"
      }
  ]))

  componentArnNoVersionMap = {
      for item in local.componentArnNoVersion : 
        item.key => item.componentArn
  }  

}

output "component" {
  value = aws_imagebuilder_component.ec2ImageBuilder_component
}

output "component_bygeneralkey"{
    value = local.componentArnNoVersionMap
}

output "component_arn"{
  value = {
    for key in keys(aws_imagebuilder_component.ec2ImageBuilder_component) : 
      key => aws_imagebuilder_component.ec2ImageBuilder_component[key].arn
  }
}


