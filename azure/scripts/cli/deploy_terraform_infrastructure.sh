#!/bin/bash
set -e

#this can be used to change the output color
RED='\033[0;31m'
NC='\033[0m' # No Color

if not hash jq 2>/dev/null; then 
  echo "installing jq"; 
  sudo apt install jq
fi

deployInfrastructure=$3

export ARM_CLIENT_ID=$SERVICE_ACCOUNT_ID
export ARM_CLIENT_SECRET=$SERVICE_ACCOUNT_PASSWORD
export ARM_TENANT_ID=$TENANT_ID
export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
export ENVIRONMENT=$1
export TF_VAR_shared_key=$SHARED_KEY
export TF_VAR_tf_main_account_id=$TERRAFORM_KEYVAULT_OBJECTID
export TF_VAR_sql_server_username=$SQL_SERVER_USERNAME
export TF_VAR_sql_server_password=$SQL_SERVER_PASSWORD
export TF_VAR_tenant_id=$TENANT_ID
export TF_VAR_kv_access_object_id=$KV_ACCESS_OBJECT_ID
export TF_VAR_kv_access_app_id=$KV_ACCESS_APP_ID
export TF_VAR_subscription_id=$SUBSCRIPTION_ID
export TF_VAR_base64_certificate=$2

if [ -z "$TERRAFORM_DEPLOYMENT" ]; then
  echo "##vso[task.logissue type=error]TERRAFORM_DEPLOYMENT is not defined"
  exit;
fi

if [ -z "$ENVIRONMENT" ]; then
  echo "##vso[task.logissue type=error]ENVIRONMENT is not defined"
  exit;
fi

#To make the file a little modular for easier readability
source $(dirname $0)/SetDeploymentVariables.sh

#To make the file a little modular for easier readability
source $(dirname $0)/SetDeploymentVariablesDefault.sh


terraformDeploymentKeyCount=$(echo "${TERRAFORM_DEPLOYMENT}" | jq -r '. | length');

if [ $deployInfrastructure -ge $terraformDeploymentKeyCount ]; then
  if [ $terraformDeploymentKeyCount -gt 0 ]; then
    deploymentKeyUpper="SECONDARY"
    resourceKeyTF="_secondary"
  fi

  SetDefaultVariables $deploymentKeyUpper
  echo "no deployment"
  exit;
fi

az login --service-principal -t ${TENANT_ID} -u ${SERVICE_ACCOUNT_ID} -p ${SERVICE_ACCOUNT_PASSWORD} 
az account set --subscription=${SUBSCRIPTION_ID}

#sample TERRAFORM_DEPLOYMENT
# [
#   {"key":"<Key used in terraform evironment variable>",
#   "rg":"<Resource Group for Terraform>", 
#   "location":"<Location for terraform RG>", 
#   "bucket":"<terraform Bucket Name>", 
#   "container":"<terraform Container Name>", 
#   "postfix":"<postfix for secondary>",
#   "skipDeployment":<true/false this is mostly used for the APIs to skip the deployments>, 
#   "apply":<true/false if true it runs the tf apply>, 
#   "skipDestroy":<true/false if true it skips the destroy step>,
#   "destroy":<true/false if true it runs the tf destroy>
#   }
# ]
#Terraform_Deployment Dev/QA
# [{"key":"northcentralus","rg":"terraform-state", "location":"North Central US", "bucket":"sampleterraform", "container":"states", "postfix":"","skipDeployment":false, "apply":false, "skipDestroy":true,"destroy":false}]

# Terraform_Deployment Staging/Prod
# [{"key":"primary","rg":"terraform-state", "location":"East US 2", "bucket":"sampleterraform", "container":"states", "postfix":"","skipDeployment":false,"apply":false, "skipDestroy":true,"destroy":false},{"key":"secondary","rg":"terraform-state", "location":"Central US", "bucket":"sampleterraform", "container":"states", "postfix":"secondary","skipDeployment":true,"apply":false, "skipDestroy":true,"destroy":false}]


#This allows the deployments to be controlled via the Library variable.  It complicates the pipeline to have it control this.  It shoudl be possible but can complicate things.
deploymentInfo=$(echo "${TERRAFORM_DEPLOYMENT}" | jq -r ".[$deployInfrastructure]")
_jq() {
  echo $deploymentInfo | jq -r ${1}
}

#output the deployment info to do verification
echo $deploymentInfo

  skipDeployment=$(_jq '.skipDeployment')

  skipDeployment=$(echo $skipDeployment | jq -r -R '. | tostring | if . == "true" then "true" else "false" end')
  deploymentApply=$(_jq '.apply')
  deploymentApply=$(echo $deploymentApply | jq -r -R '. | tostring | if . == "true" then "true" else "false" end')


  deploymentKey=$(_jq '.key')
  deploymentTFPostfix=$(_jq '.postfix')  

  #setup Upper and Lower case for Keys and the tf key
  deploymentKeyUpper=$(echo "$deploymentKey" | tr '[:lower:]' '[:upper:]')
  deploymentKeyLower=$(echo "$deploymentKey" | tr '[:upper:]' '[:lower:]')
  resourceKeyTF="_$deploymentKeyLower"

  deploymentTFPostfix=$(echo $deploymentTFPostfix | jq -r -R 'if length > 0 then "-"+. else "" end')

  SetDefaultVariables $deploymentKeyUpper
  #output the specific to make it easier to know if its skiping deployment and applying deployment
  printf "Deployment Key: ${RED}${deploymentKeyUpper}${NC}"
  if [ -z "$deploymentKeyUpper" ] || [ $deploymentKeyUpper = "NULL" ]; then
    echo ""
    echo "no deployment"
    exit;
  fi
  echo ""
  
  echo "Skip Deployment: ${skipDeployment}"
  echo "Apply Deployment: ${deploymentApply}"  

  if [ "${skipDeployment}" == "true" ]; then
    echo "##vso[task.logissue type=warning]Skip Deployment Set to true for $deploymentKey"
    printf "End Deployment Key: ${RED}${deploymentKeyUpper}${NC}"
    SetVariables $skipDeployment $deploymentKeyUpper $resourceKeyTF;
    exit;
  fi

  # DEPLOY INFRASTRUCTURE
  pushd ../terraform

  #output the version to identify any potential issues
  terraform -v

  #remove terraform init so that it ensures pointing to the correct state
  if [ -d "./.terraform" ]; then
    rm -R -f ./.terraform/
  fi

  terraform init -backend-config="./backends/${ENVIRONMENT}${deploymentTFPostfix}.tfvars"
  terraform refresh --var-file="./${ENVIRONMENT}${deploymentTFPostfix}.tfvars"
  terraform plan --var-file="./${ENVIRONMENT}${deploymentTFPostfix}.tfvars" -refresh=false

  if [ "${skipDeployment}" != "true" ] && [ "$deploymentApply" == "true" ]; then
    terraform apply -auto-approve --var-file="./${ENVIRONMENT}${deploymentTFPostfix}.tfvars"
  else
    echo "##vso[task.logissue type=warning]Not running TF Apply, output will be from last previous run."
  fi

  SetVariables $skipDeployment $deploymentKeyUpper $resourceKeyTF
  
  #this is just to add some space between the deployment info
  printf "End Deployment Key: ${RED}${deploymentKeyUpper}${NC}"
  echo ""
  echo ""



  

popd

az logout