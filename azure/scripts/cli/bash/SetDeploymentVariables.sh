source $(dirname $0)/DeploymentCheck.sh


function SetVariables() {
  
  skipDeployment=$1
  deploymentKeyUpper=$2
  resourceKeyTF=$3

  if [ "$deploymentKeyUpper" == "NORTHCENTRALUS" ]; then
    deploymentKeyUpper="PRIMARY"
  fi

  echo "Setting variables for deployment $deploymentKeyUpper"
  echo "##vso[task.setvariable variable=AZ_NO_DEPLOYMENT_${key};]false"

  if [ "${skipDeployment}" == "true" ]; then
    echo "Deployment Skipped"
    return;
  fi

  echo "##vso[task.setvariable variable=AZ_SKIP_DEPLOYMENT_${deploymentKeyUpper};]${skipDeployment}"
  echo "##vso[task.setvariable variable=AZ_APIM_NAME_RESOURCE_GROUP_${deploymentKeyUpper};]$(CheckForNull $(terraform output -json resource_group_names | jq -r ".[\"${deploymentKeyLower}:apim_rg\"]"))"
  echo "##vso[task.setvariable variable=AZ_APIM_NAME_${deploymentKeyUpper};]$(CheckForNull $(terraform output -json api_management_name | jq -r ".${resourceKeyTF}[0]"))"

}

