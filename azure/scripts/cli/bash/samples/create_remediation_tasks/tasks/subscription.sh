#!/bin/bash


function subscription_get_policy_assignment_ids() {
    if [ -z "${create_remedation_tasks}" ]; then
        create_remedation_tasks="[]"
    fi
    
    local subscription_id=$1
    local local_policy_assignment_ids='[]'
    local policy_sumary=$(az policy state summarize -o json --subscription $subscription_id 2>/dev/null)

    if [ -z "${policy_sumary}" ]; then
        echo $local_policy_assignment_ids
        return
    fi

    policy_sumary=$(echo "${policy_sumary}" | jq -rc ".policyAssignments" ) 
    if [ $(echo "${create_remedation_tasks}" | jq -r '. | length') -lt 1 ]; then
        local_policy_assignment_ids=$(echo $policy_sumary | jq --argjson arr "${local_policy_assignment_ids}" -rc "[ .[] | .policyAssignmentId as \$ID | .policyDefinitions[] | . as \$policyDefinition | .results | select(.nonCompliantResources > 0)  | {id: \$ID, value:\$policyDefinition.policyDefinitionId}  | .id ] | unique")
        echo $local_policy_assignment_ids
        return
    fi

    for policy_regex in $(echo "${create_remedation_tasks}" | jq -r '.[]'); do
        local_policy_assignment_ids=$(echo $policy_sumary | jq --argjson arr "${local_policy_assignment_ids}" -rc "[ .[] | .policyAssignmentId as \$ID | .policyDefinitions[] | . as \$policyDefinition | .results | select(.nonCompliantResources > 0)  | {id: \$ID, value:\$policyDefinition.policyDefinitionId} ] | [.[] | select(.value|test(\"${policy_regex}\"; \"i\")) | .id ] | \$arr + . | unique")
    done

    echo $local_policy_assignment_ids
}

for row in $(echo "${subscription_info}" | jq -r '. [] | @base64'); do
    subscription_id="$(parse_jq_decode $row '.key')"
    echo "processing subscriptions id - ${subscription_id}:"
    if [ ! -z "${test_subscription_id}" ]; then
        subscription_id="${test_subscription_id}"
    fi
    
    if [ $delete_existing_remediation_tasks -eq 1 ]; then
        remediation_list=$(az policy remediation list --subscription $subscription_id  2>/dev/null)
        if [ ! -z "${remediation_list}" ]; then
            remediation_list=$(echo ${remediation_list}| jq -rc )

            for row_remediation in $(echo "${remediation_list}" | jq -r '. [] | @base64'); do
                if [ $dry_run -eq 1 ]; then
                    echo "dry run: "
                    echo "    az policy remediation delete --subscription $subscription_id --name \"$(parse_jq_decode $row_remediation '.name')\""
                    echo ""
                    echo "---------------------"
                    echo ""
                    continue
                fi
                az policy remediation delete --subscription $subscription_id --name "$(parse_jq_decode $row_remediation '.name')"
            done
        fi
    fi

    policy_assignment_ids=$(subscription_get_policy_assignment_ids $subscription_id)
    if [ ! -z "${policy_assignment_ids}" ]; then
        if [ $(echo $policy_assignment_ids | jq -r ". | length") -lt 1 ]; then
            continue
        fi
        
        for policy_assignment_id in $(echo "${policy_assignment_ids}" | jq -r '. []'); do
            id_only=$(echo $(split_string_jq $policy_assignment_id "/") | jq -r ". | last" )
            if [ $dry_run -eq 1 ]; then
                echo "dry run: "
                echo "    az policy remediation create --subscription $subscription_id -n \"${id_only} - Remediation - $(date -u +"%Y%m%dT%H%M$S")Z\" --policy-assignment $policy_assignment_id"
                echo ""
                echo "---------------------"
                echo ""
                continue
            fi
            az policy remediation create --subscription $subscription_id -n "${id_only} - Remediation - $(date -u +"%Y%m%dT%H%M$S")Z" --policy-assignment $policy_assignment_id &
        done
    fi
    if [ ! -z "${test_subscription_id}" ]; then
        break
    fi
    

done
