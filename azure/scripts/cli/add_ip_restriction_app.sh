# The goal of this script was to take a list of IPs for app gateway and add them if needed to the app service

APP_NAME=$1

if [ -z "${SUBSCRIPTION_ID}" ] || [ -z "${APP_NAME}" ] || [ -z "${AZ_APIM_IP}" ]; then
    echo "Subscription ID: ${SUBSCRIPTION_ID}"
    echo "App Name: ${APP_NAME}"
    echo "APIM IP: ${AZ_APIM_IP}"
    exit 0;
fi

RuleNAME="APIM ${RESOURCE_PREFIX} IP"

function refresh_rules {
    existingRules=$(az webapp config access-restriction show --subscription "${SUBSCRIPTION_ID}" --resource-group "${RESOURCE_GROUP}" --name "${APP_NAME}" --query "ipSecurityRestrictions[?name == '${RuleNAME}' || ip_address == '${ip}']" -o json)
    existingRuleCount=`echo $existingRules | jq -r "length"`
}


for index in "${!AZ_APIM_IP[@]}";
do
    echo "APIM IP: ${AZ_APIM_IP[index]}"
    ip="${AZ_APIM_IP[index]}/32";
    apimID=$((index+1))

    refresh_rules

    refreshRules=0

    if [ $existingRuleCount -gt 0 ]; then

        ipValid=`echo $existingRules | jq -r ".[] | select(.ip_address == \"${ip}\" and .name != \"${RuleNAME}\") | if length > 0 then 1 else 0 end"`
        if [ "$ipValid" = "1" ]; then
            refreshRules=1
            echo "Not following Naming Convention Removing IP: ${ip}"
            az webapp config access-restriction remove --subscription "${SUBSCRIPTION_ID}" --resource-group "${RESOURCE_GROUP}" --name "${APP_NAME}" --ip-address "$ip"
        fi


        if [ $refreshRules -eq 1 ]; then
            echo "Refreshing Existing Rules"
            refresh_rules
        fi

        if [ $existingRuleCount -gt 0 ]; then
            refreshRules=0
            IPArray=`printf '%s\n' "${AZ_APIM_IP[@]}" | jq -R ".+\"/32\"" | jq -s . `

            for row in $(echo "${existingRules}" | jq -r '.[].ip_address | @base64'); do
                _ip() {
                echo ${row} | base64 --decode
                }

                ipLocal=`echo "$(_ip)"`
                ipValid=`echo $IPArray | jq -r "select(.[] | contains(\"${ipLocal}\")) | if length > 0 then 1 else 0 end"`
                if [ "$ipValid" != "1" ]; then
                    echo "Removing unneed IP: $ipLocal"
                    refreshRules=1
                    az webapp config access-restriction remove --subscription "${SUBSCRIPTION_ID}" --resource-group "${RESOURCE_GROUP}" --name "${APP_NAME}" --rule-name "${RuleNAME}" --ip-address "$ipLocal"
                fi

            done
            if [ $refreshRules -eq 1 ]; then
                echo "Refreshing Existing Rules"
                refresh_rules
            fi
        fi

    fi

    ipCount=0

    ipValid=`echo $existingRules | jq -r ".[] | select(.ip_address == \"${ip}\") | if length > 0 then 1 else 0 end"`
    if [ "$ipValid" == "1" ]; then
        ipCount=1
    fi

    if [ $ipCount -lt 1 ]; then
        echo "Adding Primary IP Restriction: ${ip}"
        az webapp config access-restriction add --subscription "${SUBSCRIPTION_ID}" --resource-group "${RESOURCE_GROUP}" --name "${APP_NAME}" --ip-address "${ip}" --rule-name "${RuleNAME}" --priority 300 --action Allow --description "Allow from APIM"
    fi
done
