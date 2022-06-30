#!/bin/bash
set -e

ENVIRONMNET=$1


echo "Creating RG in subscription ${SUBSCRIPTION_ID}"

az login --service-principal -t "${TENANT_ID}" -u "${SERVICE_ACCOUNT_ID}" -p "${SERVICE_ACCOUNT_PASSWORD}"
az account set -s "${SUBSCRIPTION_ID}"

if [ -z "$TERRAFORM_DEPLOYMENT" ]; then
  echo "##vso[task.logissue type=error]TERRAFORM_DEPLOYMENT is not defined"
  exit;
fi

for row in $(echo "${TERRAFORM_DEPLOYMENT}" | jq -r '.[] | @base64'); do
  _jq() {
    echo ${row} | base64 --decode | jq -r ${1}
  }

  PostFixRaw=$(_jq '.postfix')
  STATE_RESOURCE_GROUP_NAME=$(_jq '.rg') 
  REGION=$(_jq '.location')

  PostFixLower=$(echo "$PostFixRaw" | tr '[:upper:]' '[:lower:]')
  PostFix=$(echo ${PostFixLower} | jq -r -R 'if length > 0 then "-"+. else "" end')
  STATE_RESOURCE_GROUP_NAME="$(_jq '.rg')${PostFix}"
  
  if [ $(az group exists -n "${STATE_RESOURCE_GROUP_NAME}") = 'false' ]; then
    echo "create ${STATE_RESOURCE_GROUP_NAME} in ${REGION}"
    az group create -n "${STATE_RESOURCE_GROUP_NAME}" -l "${REGION}"
  else
    echo "RG (${STATE_RESOURCE_GROUP_NAME}) already exists."
  fi
done


