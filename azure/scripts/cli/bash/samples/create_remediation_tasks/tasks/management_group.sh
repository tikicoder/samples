#!/bin/bash

function mg_get_policy_assignment_ids() {
    if [ -z "${create_remedation_tasks_odata}" ]; then
        create_remedation_tasks_odata="[]"
    fi
    
    local management_group_id=$1
    local local_policy_assignment_ids='[]'
    
    if [ $(echo "${create_remedation_tasks_odata}" | jq -r '. | length') -lt 1 ]; then
        local_policy_assignment_ids=$(az policy state summarize -o json --management-group $management_group_id | jq --argjson arr "${local_policy_assignment_ids}" -rc "[ .policyAssignments[] | .policyAssignmentId as \$ID | .policyDefinitions[] | . as \$policyDefinition | .results | select(.nonCompliantResources > 0)  | {id: \$ID, value:\$policyDefinition.policyDefinitionId}  | .id ] | unique")
        echo $local_policy_assignment_ids
        return
    fi

    for policy_startswith in $(echo "${create_remedation_tasks_odata}" | jq -r '.[]'); do
        local_policy_assignment_ids=$(az policy state summarize -o json --management-group $management_group_id --filter "contains(policyDefinitionName, '${policy_startswith}')" | jq --argjson arr "${local_policy_assignment_ids}" -rc "[ .policyAssignments[] | .policyAssignmentId as \$ID | .policyDefinitions[] | . as \$policyDefinition | .results | select(.nonCompliantResources > 0)  | {id: \$ID, value:\$policyDefinition.policyDefinitionId}  | .id ] | \$arr + . | unique")    
    done

    echo $local_policy_assignment_ids
}

current_tenantid=$(az account show | jq -r ".tenantId")
current_subscriptionid=$(az account show | jq -r ".id")
switched_tenant=0

if [ "${current_tenantid}" != "${tenant_id}" ]; then
    az account set --subscription $(az account list | jq -r "[.[] | select(.tenantId == \"${tenant_id}\") ] | .[0].id ")
    switched_tenant=1
fi

if [ ! -z "${management_groups}" ]; then
    for mgid in $(split_string_jq "${management_groups}" | jq -r '. []'); do
        if [ $delete_existing_remediation_tasks -eq 1 ]; then
            remediation_list=$(az policy remediation list --management-group $mgid  2>/dev/null)
            if [ ! -z "${remediation_list}" ]; then
                remediation_list=$(echo ${remediation_list}| jq -rc )

                for row_remediation in $(echo "${remediation_list}" | jq -r '. [] | @base64'); do
                    if [ $dry_run -eq 1 ]; then
                        echo "dry run: "
                        echo "    az policy remediation delete --management-group $mgid --name \"$(parse_jq_decode $row_remediation '.name')\""
                        echo ""
                        echo "---------------------"
                        echo ""
                        continue
                    fi
                    az policy remediation delete --management-group $mgid --name "$(parse_jq_decode $row_remediation '.name')"
                done
            fi
        fi
        
        policy_assignment_ids=$(mg_get_policy_assignment_ids $mgid)
        if [ ! -z "${policy_assignment_ids}" ]; then
            if [ $(echo $policy_assignment_ids | jq -r ". | length") -lt 1 ]; then
                continue
            fi
            
            for policy_assignment_id in $(echo "${policy_assignment_ids}" | jq -r '. []'); do
                id_only=$(echo $(split_string_jq $policy_assignment_id "/") | jq -r ". | last" )
                if [ $dry_run -eq 1 ]; then
                    echo "dry run: "
                    echo "    az policy remediation create --management-group $mgid -n \"${id_only} - Remediation - $(date -u +"%Y%m%dT%H%M$S")Z\" --policy-assignment $policy_assignment_id"
                    echo ""
                    echo "---------------------"
                    echo ""
                    continue
                fi
                az policy remediation create --management-group $mgid -n "${id_only} - Remediation - $(date -u +"%Y%m%dT%H%M$S")Z" --policy-assignment $policy_assignment_id &
            done
        fi
    done
fi

if [ $switched_tenant -eq 1 ]; then
    az account set --subscription $current_subscriptionid
fi