# This is so you can create a new file that is secure or pass it in securely
settings_ssmParamters_secure = {
    ec2ImageBuilder = {
        ssmParams = {
            "/ec2ImageBuilder/TestComponent/SecureKey":"Secure", 
        }
    }
}

global_settings = {
  ec2ImageBuilder = {
    identifier = ""
  }
}

settings_vpc = {
  ec2ImageBuilder = {
    skip_resource   = false
    tags = {
      env = "nonprod"
    }

    name            = "BaseImageCreation"

    cidr_block      = "10.0.0.0/16"

    enable_dns_support = true
    enable_dns_hostnames = true


  }
}

settings_routetable = {
  ec2ImageBuilder = {
    skip_resource   = false
    tags = {
      env = "nonprod"
    }
    
    routesTables = {
      public = {
        name = "Public"

      }

      private = {
        name = "Private"

      }
      
    }

  }
}

settings_securitygroup = {
  ec2ImageBuilder = {
    skip_resource   = false
    tags = {
      env = "nonprod"
    }
    
    securityGroups = {
      main = {
        name = "%vpc_name%"
        description = "Main SG for VPC"

      }
    }

  }
}

settings_network = {
  ec2ImageBuilder = {
    skip_resource   = false
    tags = {
      env = "nonprod"
    }
    
    subnets = {
      public = {
        name = "Public"
        cidr_block = "10.0.1.0/24"
        routeTable = "public"
      }

      private = {
        name = "Private"
        cidr_block = "10.0.5.0/24"
        routeTable = "private"
      }


    }

    publicSubnets = ["public"]
    natSubnets = [
      {
        publicSubnet = "public"
        privateSubnet = "private"
      }
    ]

  }
}

settings_ec2ImageBuilder_iam_role = {
  ec2ImageBuilder = {
    skip_resource   = false
    tags = {
      env = "nonprod"
    }

    roles = {
      imagebuilder = {
        name = "ImageBuilder"
        managed_policy_arns = [ "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore", "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilderECRContainerBuilds", "arn:aws:iam::aws:policy/EC2InstanceProfileForImageBuilder"]
        assume_role_policy = {
          "Version": "2012-10-17",
          "Statement": [
              {
                  "Effect": "Allow",
                  "Principal": {
                      "Service": "ec2.amazonaws.com"
                  },
                  "Action": "sts:AssumeRole"
              }
          ]
        }
      }
    }
  }
}

settings_ec2ImageBuilder_network_endPoint = {
  ec2ImageBuilder = {
    skip_resource   = false
    tags = {
      env = "nonprod"
    }

    interfaceEndpoints = {
      imagebuilder = {
        name = "%vpc_name%.interface.us-east-1.imagebuilder"
        service_name = "com.amazonaws.us-east-1.imagebuilder"
        private_dns_enabled = true

        security_group_ids = ["main"]
        subnet_ids = ["private"]

      }
      ssm = {
        name = "%vpc_name%.interface.us-east-1.ssm"
        service_name = "com.amazonaws.us-east-1.ssm"
        private_dns_enabled = true

        security_group_ids = ["main"]
        subnet_ids = ["private"]

      }
      ssmmessages = {
        name = "%vpc_name%.interface.us-east-1.ssmmessages"
        service_name = "com.amazonaws.us-east-1.ssmmessages"
        private_dns_enabled = true

        security_group_ids = ["main"]
        subnet_ids = ["private"]

      }
      ec2messages = {
        name = "%vpc_name%.interface.us-east-1.ec2messages"
        service_name = "com.amazonaws.us-east-1.ec2messages"
        private_dns_enabled = true

        security_group_ids = ["main"]
        subnet_ids = ["private"]

      }
    }

    gatewayEndpoints = {      
      s3 = {
        name = "%vpc_name%.gateway.us-east-1.s3"
        service_name = "com.amazonaws.us-east-1.s3"

        route_table_ids = ["private"]

      }
    }

    
  }
}

settings_ssmParamters = {
  ec2ImageBuilder = {
    skip_resource   = false
    tags = {
      env = "BaseImageParams"
    }

    ssmParams = [
         
          {
            name = "/ec2ImageBuilder/TestComponent/Key"
            type = "String"
            value = "Test Value"
          }
        ]
      }
}

settings_ec2ImageBuilder_recipe = {
  ec2ImageBuilder = {
    skip_resource   = false
    tags = {
      env = "nonprod"
    }

    recipes = {

      ProdBaseAWSLinux2AMD64 = {
        name = "ProdBase-AWSLinux-2-AMD64"
        parent_image = "arn:aws:imagebuilder:us-east-1:aws:image/amazon-linux-2-x86/x.x.x"

        versions = [
          {
            version = "0.0.1"

            components = [
              "TestComponent",         
              "arn:aws:imagebuilder:us-east-1:aws:component/update-linux-kernel-mainline/x.x.x",
              "arn:aws:imagebuilder:us-east-1:aws:component/update-linux/x.x.x",
              "arn:aws:imagebuilder:us-east-1:aws:component/amazon-cloudwatch-agent-linux/x.x.x",
              "arn:aws:imagebuilder:us-east-1:aws:component/aws-cli-version-2-linux/x.x.x", # ensures AWS CLI v2 is installed    
              "arn:aws:imagebuilder:us-east-1:aws:component/stig-build-linux-high/x.x.x",
              
            ]

            ebs = [
              {
                device_name = "/dev/xvda"
                ebs_delete_on_termination = true
                ebs_volume_size = 8 # Base AIM uses max 3 gb
                ebs_volume_type = "gp3"
              },              
              { # This is ment to keep content 
                device_name = "/dev/xvdb"
                ebs_delete_on_termination = true
                ebs_volume_size = 12 
                ebs_volume_type = "gp3"
              }
            ]
          }
        ]
      }
    }
  }
}

settings_ec2ImageBuilder_pipeline = {
  ec2ImageBuilder = {
    skip_resource   = false
    tags = {
      env = "nonprod"
    }

    
    pipelines = [  
      {
        image_recipe_arn = "ProdBaseAWSLinux2AMD64:0.0.1"
        name = "ProdBase-AWSLinux-2-AMD64"        
      },      
    ]

    distribution_configuration = [   
      {
        name = "ProdBase-AWSLinux-2-AMD64"
        description = ""

        distributions = [
          {
            region = "us-east-1"
            ami_distribution_configuration = {
              ami_tags = {
                
              }

            }
          },
        ]

      },
    ]

    infrastructure_configuration = {
      name = "GeneralPipelineInfastructure"
      description = ""

      instance_profile_name = "imagebuilder"
      instance_types = ["t3.micro", "t2.micro"]

      security_group_ids = ["main"]
      subnet_id = "private"

      terminate_instance_on_failure = true
    }
  }
}


settings_ec2ImageBuilder_component = {
  ec2ImageBuilder = {
    skip_resource   = false
    tags = {
      env = "nonprod"
    }

    components = {
      TestComponent = {
        name = "TestComponent"
        platform = "Linux"
        description = ""
        supported_os_versions = []

        versions = [
          {
            version = "0.0.1"
            data = "/variable_data/imageBuilderFiles/TestComponent.yml"
          }
        ]
      }
    }
  }
}