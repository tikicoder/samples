# The goal of this script is to allow the avibility tests endpoint to reach the app service

APP_NAME=$1
APP_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

if [ -z "${SUBSCRIPTION_ID}" ] || [ -z "${APP_NAME}" ]; then
    echo "Subscription ID: ${SUBSCRIPTION_ID}"
    echo "App Name: ${APP_NAME}"
    exit 0;
fi

#Ip from https://docs.microsoft.com/en-us/azure/azure-monitor/app/ip-addresses#availability-tests

LOCATIONS='["EastUS", "WestUS" ,"CentralUS", "NorthCentralUS", "SouthCentralUS"]'
APP_INSIGHT_Availability_EastUS='"20.42.35.32/28", "20.42.35.64/28", "20.42.35.80/28", "20.42.35.96/28", "20.42.35.112/28", "20.42.35.128/28"'
APP_INSIGHT_Availability_WestUS='"40.91.82.48/28", "40.91.82.64/28", "40.91.82.80/28", "40.91.82.96/28", "40.91.82.112/28", "40.91.82.128/28"'
APP_INSIGHT_Availability_CentralUS='"13.86.97.224/28", "13.86.97.240/28", "13.86.98.48/28", "13.86.98.0/28", "13.86.98.16/28", "13.86.98.64/28"'
APP_INSIGHT_Availability_NorthCentralUS='"23.100.224.16/28", "23.100.224.32/28", "23.100.224.48/28", "23.100.224.64/28", "23.100.224.80/28","23.100.224.96/28", "23.100.224.112/28", "23.100.225.0/28"'
APP_INSIGHT_Availability_SouthCentralUS='"20.45.5.160/28", "20.45.5.176/28", "20.45.5.192/28", "20.45.5.208/28", "20.45.5.224/28", "20.45.5.240/28"'

function process_location {
    LOCATION=$1
    IPArrayVariable="APP_INSIGHT_Availability_${LOCATION}"
    IPArray="[ ${!IPArrayVariable} ]"
    RuleNAME="APP_INSIGHT_Avail ${LOCATION}"

    existingRules="$(az webapp config access-restriction show --subscription "${SUBSCRIPTION_ID}" --resource-group "${RESOURCE_GROUP}" --name "${APP_NAME}" --query "ipSecurityRestrictions[?starts_with(to_string(name), '${RuleNAME}')]" -o json)"
    existingRuleCount=`echo $existingRules | jq -r "length"`

    if [ $existingRuleCount -gt 0 ]; then
        refreshRules=0
        for row in $(echo "${existingRules}" | jq -r '.[].ip_address | @base64'); do
            _ip() {
            echo ${row} | base64 --decode
            }

            ip=`echo "$(_ip)"`
            ipValid=`echo $IPArray | jq -r "select(.[] | contains(\"${ip}\")) | if length > 0 then 1 else 0 end"`
            if [ "$ipValid" != "1" ]; then
                echo "Removing IP: $ip"
                refreshRules=1
                az webapp config access-restriction remove --subscription "${SUBSCRIPTION_ID}" --resource-group "${RESOURCE_GROUP}" --name "${APP_NAME}" --rule-name "${RuleNAME}" --ip-address "$ip"
            fi

        done
        if [ $refreshRules -eq 1 ]; then
            echo "Refreshing Existing Rules"
            existingRules="$(az webapp config access-restriction show --subscription "${SUBSCRIPTION_ID}" --resource-group "${RESOURCE_GROUP}" --name "${APP_NAME}" --query "ipSecurityRestrictions[?starts_with(to_string(name), '${RuleNAME}')]" -o json)"
            existingRuleCount=`echo $existingRules | jq -r "length"`
        fi
    fi

    for row in $(echo "${IPArray}" | jq -r '.[] | @base64'); do
        _ip() {
        echo ${row} | base64 --decode
        }

        ip=`echo "$(_ip)"`
        ipValid=`echo $existingRules | jq -r ".[] | select(.ip_address == \"${ip}\") | if length > 0 then 1 else 0 end"`
        ipCount=0
        if [ "$ipValid" == "1" ]; then
            ipCount=1
        fi

        if [ $ipCount -lt 1 ]; then
            echo "Adding App Insight Test IP: ${ip}"
            az webapp config access-restriction add --subscription "${SUBSCRIPTION_ID}" --resource-group "${RESOURCE_GROUP}" --name "${APP_NAME}" --ip-address "${ip}" --rule-name "${RuleNAME}" --priority 100 --action Allow --description "${IPArrayVariable} ${ip}"
        fi
    done
}


for row in $(echo "${LOCATIONS}" | jq -r ".[]"); do
    location=`echo "$row"`

    echo "Processing location: ${location}"
    process_location "$location"
done

APPLIST=`az webapp list -o json --query "[?name=='${APP_NAME}']"`
HOSTNAME=`echo $APPLIST | jq -r '.[].hostNames[0]'`
APP_LOCATION=`echo $APPLIST | jq -r '.[].location'`
APPINSIGHT_LOCATION=`az account list-locations --query "[?displayName=='${APP_LOCATION}'].name" -o json | jq -r '.[0]'`

APPINSIGHT=`az resource list --subscription $SUBSCRIPTION_ID --query "[?contains(id, '/Microsoft.Insights/') && location == '${APPINSIGHT_LOCATION}']" -o json`
APPINSIGHT_RG=`echo $APPINSIGHT | jq -r '.[0].resourceGroup'`
APPINSIGHT_NAME=`echo $APPINSIGHT | jq -r '.[0].name'`

az deployment group create \
    --name "DeployAvailabilityTest-${APP_NAME}" \
    --resource-group $APPINSIGHT_RG \
    --template-file "${APP_DIR}/deployment/app_insight/availability/template.json" \
   --parameters "{
            \"appName\": {
                \"value\": \"${APPINSIGHT_NAME}\"
            },
            \"pingTestName\": {
                \"value\": \"Ping Test - ${APP_NAME}\"
            },
            \"pingAlertRuleName\": {
                \"value\": \"Ping Alert - ${APP_NAME}\"
            },
            \"pingURL\": {
                \"value\": \"https://${HOSTNAME}/health\"
            },
            \"location\": {
                \"value\": \"${APPINSIGHT_LOCATION}\"
            },
            \"pingText\": {
                \"value\": \"\"
            },
            \"actionGroupId\": {
                \"value\": \"\"
            }
        }"
