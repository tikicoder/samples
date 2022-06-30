APP_NAME=$1
FUNC_NAME=$2
VNET_NAME=$3
APP_SUBNET=$4
FUNC_SUBNET=$5
RESOURCE_GROUP=$6

echo "Web App VNet Integration"
az webapp vnet-integration add --name ${APP_NAME} --resource-group ${RESOURCE_GROUP} --vnet ${VNET_NAME} --subnet ${APP_SUBNET}
az webapp vnet-integration add --name ${APP_NAME} --resource-group ${RESOURCE_GROUP} --vnet ${VNET_NAME} --subnet ${APP_SUBNET} --slot staging

echo "Function App VNet Integration"
az functionapp vnet-integration add --name ${FUNC_NAME} --resource-group ${RESOURCE_GROUP} --vnet ${VNET_NAME} --subnet ${FUNC_SUBNET}
az functionapp vnet-integration add --name ${FUNC_NAME} --resource-group ${RESOURCE_GROUP} --vnet ${VNET_NAME} --subnet ${FUNC_SUBNET} --slot staging
