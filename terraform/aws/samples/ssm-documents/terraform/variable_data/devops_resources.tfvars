global_settings = {
  devops = {
    identifier = ""
  }
}

settings_ssm_document = {
  devops = {
    crowdstrike = {
      skip_resource   = false
      tags = {

      }

      name            = "ManageCrowdstrikeInstance"
      version_name      = "Init"

      document_type = "Automation"
      document_format = "YAML"

      content = "/variable_data/sm_documents/crowdstrike.yaml"

      permissions = {
        type = "Share"
        account_ids = ""
      }


    }
    threatstack = {
      skip_resource   = false
      tags = {

      }

      name            = "ManageThreatStackInstance"
      version_name      = "Init"

      document_type = "Automation"
      document_format = "YAML"

      content = "/variable_data/sm_documents/threatstack.yaml"

      permissions = {
        type = "Share"
        account_ids = ""
      }


    }
    datadog = {
      skip_resource   = false
      tags = {

      }

      name            = "CustomDataDog"
      version_name      = "Init"

      document_type = "Automation"
      document_format = "YAML"

      content = "/variable_data/sm_documents/datadog.yaml"

      permissions = {
        type = "Share"
        account_ids = ""
      }


    }
    rapid7 = {
      skip_resource   = false
      tags = {

      }

      name            = "CustomRapid7"
      version_name      = "Init"

      document_type = "Automation"
      document_format = "YAML"

      content = "/variable_data/sm_documents/rapid7.yaml"

      permissions = {
        type = "Share"
        account_ids = ""
      }


    }
    manageservice = {
      skip_resource   = false
      tags = {

      }

      name            = "CustomManageInstanceService"
      version_name      = "Init"

      document_type = "Automation"
      document_format = "YAML"

      content = "/variable_data/sm_documents/manage_service.yaml"

      permissions = {
        type = "Share"
        account_ids = ""
      }


    }
  }
}