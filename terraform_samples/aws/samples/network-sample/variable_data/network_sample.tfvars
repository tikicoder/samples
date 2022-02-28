global_settings = {
  sample = {
    identifier = ""    
    tags = { "environment" = "sample" }
  }
}

settings_network = {
  sample = {
    vpc = {
      mainVPC = {
        skip_resource = false
        
        name ="Sample VPC"

        cidr_block = "10.0.0.0/16"

        enable_dns_support = true
        enable_dns_hostnames = true

      }
    }

    route_table = {
      public = {
        skip_resource = false
        name = "Public"
        vpc_id = "mainVPC"
      }
      private = {
        skip_resource = false
        name = "Private"
        vpc_id = "mainVPC"
      }
    }

    security_group = {
      main = {
        skip_resource = false
        name = "%vpc_name%"
        description = "Main SG for VPC"
        vpc_id = "mainVPC"

      }
    }

    network = {
      main = {
        vpc_id = "mainVPC"
        
        subnets = {
          public = {
            skip_resource = false
            name = "Public"
            cidr_block = "10.0.1.0/24"
            route_table = "public"
          }

          private = {
            skip_resource = false
            name = "Private"
            cidr_block = "10.0.5.0/24"
            route_table = "private"
          }

        }

        public_subnets = [ "public"  ]
        
        nat_subnets = [
          {
            public = "public"
            private = "private"
          }
        ]

      }
    }

    endpoint = {
      main = {
        skip_resource = false
        vpc_id = "mainVPC"
        network = "main"

        endpoint = {
          monitering = {
            name = "%vpc_name%.interface.us-east-1.monitoring"
            security_group_ids = ["main"]
            service_name = "com.amazonaws.us-east-1.monitoring"
            subnet_ids = ["private"]
            private_dns_enabled = true
            vpc_endpoint_type = "Interface"
          }
        }

      }
    }

  }
}

