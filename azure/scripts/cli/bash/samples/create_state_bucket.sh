#!/bin/bash
set -e

ENVIRONMNET=$1

echo "Creating state bucket in subscription ${SUBSCRIPTION_ID}"

az login --service-principal -t ${TENANT_ID} -u ${SERVICE_ACCOUNT_ID} -p ${SERVICE_ACCOUNT_PASSWORD}
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
  
  REGION=$(_jq '.location')
  CONTAINER_NAME=$(_jq '.container')

  PostFixLower=$(echo "$PostFixRaw" | tr '[:upper:]' '[:lower:]')
  PostFix=$(echo $PostFixLower | jq -r -R 'if length > 0 then "-"+. else "" end')

  STATE_RESOURCE_GROUP_NAME="$(_jq '.rg')${PostFix}"
  BLOB_BUCKET_NAME="$(_jq '.bucket')${ENVIRONMNET}${PostFixLower}"

  BLOB_BUCKET_NAME_LENGTH=$(echo ${#BLOB_BUCKET_NAME})
  if [ $BLOB_BUCKET_NAME_LENGTH -gt 23 ]; then
      BLOB_BUCKET_NAME=$(echo $BLOB_BUCKET_NAME | cut -c1-23)
  fi
  
  # Create the storage account
  if [ $(az storage account check-name -n ${BLOB_BUCKET_NAME} | jq -r '.nameAvailable') = 'true' ]; then
    echo "create ${BLOB_BUCKET_NAME} (${STATE_RESOURCE_GROUP_NAME}) -  ${REGION}"
    az storage account create -n "${BLOB_BUCKET_NAME}" -g "${STATE_RESOURCE_GROUP_NAME}" -l "${REGION}"
  else
    echo "Storage account already exists."
  fi

  # Get the storage account key
  ARM_ACCESS_KEY=$(az storage account keys list -n "${BLOB_BUCKET_NAME}" | jq -r '.[] | select(.keyName=="key1") | .value')

  # Create the blob container
  if [ $(az storage container exists -n ${CONTAINER_NAME} --account-name ${BLOB_BUCKET_NAME} --account-key "${ARM_ACCESS_KEY}" | jq -r ".exists") = 'false' ]; then    
    echo "create ${CONTAINER_NAME} (${BLOB_BUCKET_NAME})"
    az storage container create -n ${CONTAINER_NAME} --account-name ${BLOB_BUCKET_NAME} --account-key ${ARM_ACCESS_KEY}
  else
    echo "Container already exists."
  fi
done


