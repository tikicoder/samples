export APP_NAME=$1
export FUNC_NAME=$2
export IP_ADDRESS=$3
export RESOURCE_GROUP=$4

az webapp deployment slot delete --name ${APP_NAME} --resource-group ${RESOURCE_GROUP} --slot staging
az functionapp deployment slot delete --name ${FUNC_NAME} --resource-group ${RESOURCE_GROUP} --slot staging

az webapp deployment slot create --name ${APP_NAME} --resource-group ${RESOURCE_GROUP} --slot staging --configuration-source ${APP_NAME}
az functionapp deployment slot create --name ${FUNC_NAME} --resource-group ${RESOURCE_GROUP} --slot staging --configuration-source ${FUNC_NAME}

az webapp start --name ${APP_NAME} --resource-group ${RESOURCE_GROUP} --slot staging
az functionapp start --name ${FUNC_NAME} --resource-group ${RESOURCE_GROUP} --slot staging

az webapp config access-restriction add --name ${APP_NAME} --resource-group ${RESOURCE_GROUP} --ip-address ${IP_ADDRESS} --rule-name "DevOps Pipeline" --priority 100 --action Allow --slot staging
