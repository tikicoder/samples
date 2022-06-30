#!/bin/bash
set -e

export ARM_CLIENT_ID=$SERVICE_ACCOUNT_ID
export ARM_CLIENT_SECRET=$SERVICE_ACCOUNT_PASSWORD
export ARM_TENANT_ID=$TENANT_ID
export ARM_SUBSCRIPTION_ID=$SUBSCRIPTION_ID
export ENVIRONMENT=$1
export TF_VAR_shared_key=$SHARED_KEY
export TF_VAR_sql_server_username=$SQL_SERVER_USERNAME
export TF_VAR_sql_server_password=$SQL_SERVER_PASSWORD
export TF_VAR_tenant_id=$TENANT_ID
export TF_VAR_kv_access_object_id=$KV_ACCESS_OBJECT_ID
export TF_VAR_kv_access_app_id=$KV_ACCESS_APP_ID
export TF_VAR_subscription_id=$SUBSCRIPTION_ID

if [ -z "$TERRAFORM_DEPLOYMENT" ]; then
  echo "##vso[task.logissue type=error]TERRAFORM_DEPLOYMENT is not defined"
  exit;
fi

if [ -z "$ENVIRONMENT" ]; then
  echo "##vso[task.logissue type=error]ENVIRONMENT is not defined"
  exit;
fi

az login --service-principal -t ${TENANT_ID} -u ${SERVICE_ACCOUNT_ID} -p ${SERVICE_ACCOUNT_PASSWORD} 
az account set --subscription=${SUBSCRIPTION_ID}

# DESTROY INFRASTRUCTURE
pushd ../terraform


for row in $(echo "${TERRAFORM_DEPLOYMENT}" | jq -r '.[] | @base64'); do
  _jq() {
    echo ${row} | base64 --decode | jq -r ${1}
  }

  skipDestroy=$(_jq '.skipDestroy')
  skipDestroy=$(echo $skipDestroy | jq -r -R '. | tostring | if . == "true" then "true" else "false" end')
  deploymentDestroy=$(_jq '.destroy')
  deploymentDestroy=$(echo $deploymentDestroy | jq -r -R '. | tostring | if . == "true" then "true" else "false" end')



  #remove terraform init so that it ensures pointing to the correct state
  if [ -d "./.terraform" ]; then
    rm -R -f ./.terraform/
  fi

  deploymentKey=$(_jq '.key')
  deploymentTFPostfix=$(_jq '.postfix')
  deploymentTFState=$(_jq '.tfState')

  deploymentKeyUpper=$(echo "$deploymentKey" | tr '[:lower:]' '[:upper:]')
  deploymentKeyLower=$(echo "$deploymentKey" | tr '[:upper:]' '[:lower:]')
  resourceKeyTF="_$deploymentKeyLower"

  deploymentTFPostfix=$(echo $deploymentTFPostfix | jq -r -R 'if length > 0 then "-"+. else "" end')
  deploymentTFState=$(echo $deploymentTFState | jq -r -R 'if length > 0 then "-"+. else "" end')

  #output the row to do verification
  echo "$row" | base64 --decode | jq -r "."
  
  #output the specific to make it easier to know if its skiping deployment and applying deployment
  echo ""
  echo "Deployment Key: ${deploymentKeyUpper}"
  echo "Skip Deployment: ${skipDeployment}"
  echo "Apply Deployment: ${deploymentApply}"

  if [ "${skipDestroy}" != "true" ]; then
    echo "##vso[task.logissue type=warning]Skipping destroy for deployment: ${deploymentKey}"
    continue;
  fi

  terraform init -backend-config="./backends/${ENVIRONMENT}${deploymentTFPostfix}.tfvars"
  terraform refresh --var-file="${ENVIRONMENT}.tfvars" -refresh=false

  terraform plan -destroy --var-file="${ENVIRONMENT}${deploymentTFPostfix}.tfvars"

  if [ "$deploymentDestroy" == "true" ]; then
    # terraform destroy -auto-approve --var-file="${ENVIRONMENT}${deploymentTFPostfix}.tfvars" --state="terraform-infrastructure-${ENVIRONMENT}-updated.state"
    echo "##vso[task.logissue type=error]Disabled apply for testing"
  fi
  

done
  


popd
