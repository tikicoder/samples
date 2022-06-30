function SetDefaultVariables() {

  key=$(echo "$1" | tr '[:lower:]' '[:upper:]')
  if [ "$key" = "NORTHCENTRALUS" ]; then
    key="PRIMARY"
  fi
  
  echo "setting default variables: $key"  

  echo "##vso[task.setvariable variable=AZ_NO_DEPLOYMENT_${key};]true"
  echo "##vso[task.setvariable variable=AZ_SKIP_DEPLOYMENT_${key};]true"
  echo "##vso[task.setvariable variable=AZ_APIM_NAME_RESOURCE_GROUP_${key};]_"
  echo "##vso[task.setvariable variable=AZ_APIM_NAME_${key};]_" 

  echo "setting default variables done: $key"  

}