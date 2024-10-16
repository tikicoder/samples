#!/bin/bash

function get_v2_login_experience(){
    v2_login_experience=$(az config get core.login_experience_v2 --only-show-errors 2>/dev/null)
    if [ "$v2_login_experience" == "" ]; then
        v2_login_experience="on"
    fi

    echo $v2_login_experience
}

function azcli_login(){
    if [ $# -lt 1 ]; then
        az login
        return
    fi

    az login --tenant $1
}

function process_login_request(){
    if [ $# -lt 1 ]; then
        if [ ! -z "${DEFAULT_AZURE_TENANT}" ]; then
            azcli_login "${DEFAULT_AZURE_TENANT}"
            return
        fi

        uniqueTenantCount=$(az account list --query "[].homeTenantId" | jq -r ". | unique | length")
        if [ $uniqueTenantCount -lt 1 ]; then
            azcli_login
            return
        fi
    
    v2_login_experience=$(get_v2_login_experience)

    if [ "$v2_login_experience" != "off" ]; then
        az config set core.login_experience_v2=off
    fi
    
    lastTenantId=$(az account list --query "[].homeTenantId" | jq -r ". | unique | .[-1]")
    for tenantId in $(az account list --query "[].homeTenantId" | jq -r ". | unique | .[]"); do
        echo "Authenticating ${tenantId}"
        # azcli_login "${tenantId}"
        echo "Please close the browser to prevent any caching issues and press enter to continue"
        if [ $tenantId != $lastTenantId ]; then
            read -p "Press enter to continue"
        fi
    done

    if [ "$v2_login_experience" != "off" ]; then
        az config set core.login_experience_v2=$v2_login_experience
    fi 
    echo "There are multiple tenants please ensure correct is set to default"
    echo "current default subscription"
    az account show
    
    return
    fi
}

if [ ! -z "${DEFAULT_AZURE_SUBSCRIPTION}" ]; then
    v2_login_experience=$(get_v2_login_experience)

    if [ "$v2_login_experience" != "off" ]; then
        az config set core.login_experience_v2=off
    fi
fi



if [ $# -lt 1 ]; then
    process_login_request
    exit
fi

process_login_request $1

if [ ! -z "${DEFAULT_AZURE_SUBSCRIPTION}" ]; then
    az account set --subscription "${DEFAULT_AZURE_SUBSCRIPTION}"
    if [ "$v2_login_experience" != "off" ]; then
        az config set core.login_experience_v2=$v2_login_experience
    fi
fi