export APP_NAME=$1
export FUNC_NAME=$2
export RESOURCE_GROUP=$3

az webapp deployment slot swap --name ${APP_NAME} --resource-group ${RESOURCE_GROUP} --slot staging --target-slot production
az functionapp deployment slot swap --name ${FUNC_NAME} --resource-group ${RESOURCE_GROUP} --slot staging --target-slot production

az webapp stop --name ${APP_NAME} --resource-group ${RESOURCE_GROUP} --slot staging
az functionapp stop --name ${FUNC_NAME} --resource-group ${RESOURCE_GROUP} --slot staging
