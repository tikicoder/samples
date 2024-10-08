#!/bin/bash
if [ ! $(command -v "realpath") ]; then
    realpath() {
    OURPWD=$PWD
    cd "$(dirname "$1")"
    LINK=$(readlink "$(basename "$1")")
    while [ "$LINK" ]; do
        cd "$(dirname "$LINK")"
        LINK=$(readlink "$(basename "$1")")
    done
    REALPATH="$PWD/$(basename "$1")"
    cd "$OURPWD"
    echo "$REALPATH"
    }
fi

full_path=$(realpath $0)
dir_path=$(dirname $full_path)
parent_path=$(realpath "${dir_path}/../")
root_path=$(realpath "${dir_path}/../../")



#this can be used to change the output color
RED='\033[0;31m'
NC='\033[0m' # No Color

source "${dir_path}/functions/defaults.sh"

# this is done as a way to expand the script incase there is something that shouldn't be in the repo
if [ -f "${dir_path}/functions/defaults_variables_override.sh" ]; then
    source "${dir_path}/functions/defaults_variables_override.sh"
fi

source "${dir_path}/functions/validate_flags.sh"
validate_flags $@


if [ -z "${existing_assignments_file}" ]; then
    existing_assignments_file="existing_assignments.$(date +"%Y%m%d").txt"
fi

if [ $skip_all_delete -ne 0 ]; then
    echo "--skip-delete flag set skipping all delete"
fi

if [ $skip_blueprint_delete -ne 0 ]; then
    echo "--skip-delete-bp flag set skipping blueprint delete"
fi

if [ $skip_policy_delete -ne 0 ]; then
    echo "--skip-delete-policy flag set skipping policy delete"
fi

if [ $run_assignment_creation -ne 0 ]; then
    echo "--run-assignment flag set Will reassign Blueprints based on file: ${existing_assignments_file}"
fi

if [ ! -z "${tenant_id}" ]; then
    subscription_info=$(az account list --query "[?homeTenantId == '${tenant_id}']" | jq -r -c "[.[] | {(.id):.name}]")
else
    subscription_info=$(az account list | jq -r -c "[.[] | {(.id):.name}]")
fi

subscription_info=$(echo $subscription_info | jq -r " [.[]  | to_entries | add]")

if [ ! -z "${subscription_filter}" ]; then
    subscription_filter=$(echo "\"${subscription_filter}\"" | jq -rc "[. | split(\"[,;\\\s]\";\"ig\") | .[] | rtrimstr(\" \") | ltrimstr(\" \") | select(. != \"\")]")
    subscription_info=$(echo "${subscription_info}" | jq --argjson sub_include "${subscription_filter}" -rc "[.[] | select(.key | IN(\$sub_include[])) ]")
fi


if [ ! -z "${subscription_exclude}" ]; then
    subscription_exclude=$(echo "\"${subscription_exclude}\"" | jq -rc "[. | split(\"[,;\\\s]\";\"ig\") | .[] | rtrimstr(\" \") | ltrimstr(\" \") | select(. != \"\")]")
    subscription_info=$(echo "${subscription_info}" | jq --argjson sub_exclude "${subscription_exclude}" -rc "[.[] | select(.key | IN(\$sub_exclude[]) | not) ]")
fi

if [ ! -z "${blueprint_exclude}" ]; then
    blueprint_exclude=$(echo "\"${blueprint_exclude}\"" | jq -rc "[. | split(\"[,;\\\s]\";\"ig\") | .[] | rtrimstr(\" \") | ltrimstr(\" \") | select(. != \"\")]")
fi

if [ ! -z "${blueprint_filter}" ]; then
    blueprint_filter=$(echo "\"${blueprint_filter}\"" | jq -rc "[. | split(\"[,;\\\s]\";\"ig\") | .[] | rtrimstr(\" \") | ltrimstr(\" \") | select(. != \"\")]")
fi

subscription_blueprint_assignment="{}"

echo ""
echo "Processing $(echo ${subscription_info} | jq -r ". | length") subscription(s)"
echo ""


function check_bp_delete_if_failed(){
    subscription=$1
    assignment_name=$2
    if [ $# -gt 2 ]; then
        blueprint_assignment_list=$3
    else
        blueprint_assignment_list=$(az blueprint assignment list --subscription "${subscription}" | jq -c)
    fi

    blueprint_assignment_count=$(echo $blueprint_assignment_list | jq -r "[.[] | select(.name == \"${assignment_name}\")] | length ")

    
    if [ $blueprint_assignment_count -lt 1 ]; then
        return;
    fi

    provisioningState=$(echo $blueprint_assignment_list | jq -r "[.[] | select(.name == \"${assignment_name}\")] | .[0].provisioningState | ascii_downcase")
    if [ "${provisioningState}" == "failed" ]; then
        az blueprint assignment delete -y --subscription "${subscription}" --name "${assignment_name}"
    fi
}

function assign_bp_subscription(){
    
    local_subscription_id=$1
    assignment_name=$2
    assignment_location=$3
    blueprintId=$4
    blueprint_parameters=$5
    blueprint_identity=$6

    echo "Assigning Blueprint - ${local_subscription_id} - ${assignment_name} - ${blueprintId}"
    az blueprint assignment create --subscription "${local_subscription_id}" --name \
        "${assignment_name}" --location "${assignment_location}" --identity-type UserAssigned \
        --blueprint-version "${blueprintId}" \
        --parameters "${blueprint_parameters}" \
        --user-assigned-identity "${blueprint_identity}" \
        --locks-mode AllResourcesDoNotDelete &
}

function get_policy_assignment_names() {
    local local_pilicy_assignment_ids='[]'

    if [ -z "${existing_policies_tmp}" ]; then
        echo "[]"
        return
    fi
    
    if [ $(echo "${existing_policies_tmp}" | jq -r '. | length') -gt 0 ]; then
        for policy_regex in $(echo "${existing_policies_tmp}" | jq -r '.[]'); do
            local_pilicy_assignment_ids=$(echo $policy_sumary | jq --argjson arr "${local_pilicy_assignment_ids}" -rc "[ .[] | select(.policyDefinitionId|test(\"${policy_regex}\"; \"i\")) | .name ] | \$arr + . | unique")
        done
    else
        local_pilicy_assignment_ids=$(echo $policy_sumary | jq --argjson arr "${local_pilicy_assignment_ids}" -rc "[ .[] | .name ] | \$arr + . | unique")
    fi

    echo $local_pilicy_assignment_ids
}

if [ $skip_assignment_creation -eq 0 ]; then
    for row in $(echo "${subscription_info}" | jq -r '. [] | @base64'); do
        _jq(){
            echo ${row} | base64 --decode | jq -r ${1}
        }
        
        echo ""
        echo ""
        echo "Processing $(_jq '.value') - $(_jq '.key')"
        blueprint_assignment=$(az blueprint assignment list --subscription "$(_jq '.key')" | jq -rc ".")
        
        blueprint_assignment_principal=$(echo "${blueprint_assignment}" | jq -rc "[.[] | [.identity.userAssignedIdentities[].principalId, .identity.userAssignedIdentities[].clientId]] | flatten | unique")
        blueprint_assignment=$(echo "${blueprint_assignment}" | jq -rc "[.[] | {id: .id, name: .name, blueprintId: .blueprintId, blueprintNameId_split: (.blueprintId | split(\"/\")), blueprintName: (.blueprintId | split(\"/\")[-3]), blueprintVersion: (.blueprintId | split(\"/\")[-1]), identity: (.identity.userAssignedIdentities | keys | .[0]), location: .location, parameters: .parameters}]")
        

        if [ ! -z "${blueprint_exclude}" ]; then
            blueprint_assignment=$(echo "${blueprint_assignment}" | jq --argjson bp_exclude "${blueprint_exclude}" -rc "[.[] | select(.blueprintName | IN(\$bp_exclude[]) | not) ]")
        fi

        if [ ! -z "${blueprint_filter}" ]; then
            blueprint_assignment=$(echo "${blueprint_assignment}" | jq --argjson bp_filter "${blueprint_filter}" -rc "[.[] | select(.blueprintName | IN(\$bp_filter[])) ]")
        fi
        

        if [ $run_force_delete_policies -eq 1 ]; then
            # Force Deleted extra policies
            # Update the existing_policies_tmp with a json array of display names
            policy_sumary=$(az policy assignment list --subscription "$(_jq '.key')"  -o json | jq -rc ".")  
            pilicy_assignment_names=$(get_policy_assignment_names "$(_jq '.key')")

            if [ ! -z "${pilicy_assignment_names}" ]; then
                for assignment_name in $(echo "${pilicy_assignment_names}" | jq -r '. []'); do

                    echo "Deleting Policy Old - ${assignment_name}"
                    az policy assignment delete --subscription "$(_jq '.key')" --name "${assignment_name}" &
                done

                while [ $(echo "${pilicy_assignment_names}" | jq -r '. | length') -gt 0 ]
                do
                    policy_sumary=$(az policy assignment list --subscription "$(_jq '.key')"  -o json | jq -rc ".")  
                    pilicy_assignment_names=$(get_policy_assignment_names "$(_jq '.key')")
                    sleep 1
                done

                az policy assignment list --subscription "$(_jq '.key')" | jq  -r ".[].displayName"
            fi
        fi
        

        subscription_policies=$(az policy assignment list --subscription "$(_jq '.key')" --query "[].{id: id, name: name, createdBy: metadata.createdBy, updatedBy: metadata.updatedBy}")
        delete_policies=$(echo "${subscription_policies}" | jq --argjson principal "${blueprint_assignment_principal}" -rc "[.[] | select((.createdBy | IN(\$principal[])) or select(.updatedBy | IN(\$principal[])))]")
        not_delete_policies=$(echo "${subscription_policies}" | jq --argjson principal "${blueprint_assignment_principal}" -rc "[.[] | select((.createdBy | IN(\$principal[]) | not) and select(.updatedBy | IN(\$principal[]) | not))]")

        subscription_blueprint_assignment=$(echo "${subscription_blueprint_assignment}" | jq -rc ". | .\"$(_jq '.key')\"={assignment: $blueprint_assignment, delete_policies:$delete_policies, not_delete_policies:$not_delete_policies}")

        if [ $skip_all_delete -eq 0 ] && [ $skip_blueprint_delete -eq 0 ]; then
            for row_assignment in $(echo "${blueprint_assignment}" | jq -r '. [] | @base64'); do
                _jq_assignment(){
                    echo ${row_assignment} | base64 --decode | jq -r ${1}
                }
                
                echo "Deleting Blueprint - $(_jq_assignment '.name')"
                az blueprint assignment delete -y --subscription "$(_jq '.key')" --name "$(_jq_assignment '.name')" &
                
            done
        fi

        if [ $skip_all_delete -eq 0 ] && [ $skip_blueprint_delete -eq 0 ] && [ $skip_policy_delete -eq 0 ]; then
            for row_assignment in $(echo "${blueprint_assignment}" | jq -r '. [] | @base64'); do
                _jq_assignment(){
                    echo ${row_assignment} | base64 --decode | jq -r ${1}
                }
                
                echo "Pending Blueprint Deletion - $(_jq_assignment '.name')"
                blueprint_assignment_count=$(az blueprint assignment list --subscription "$(_jq '.key')" | jq -r "[.[] | select(.name == \"$(_jq_assignment '.name')\")] | length ")
                while [ $blueprint_assignment_count -gt 0 ]
                do
                    blueprint_assignment_list=$(az blueprint assignment list --subscription "$(_jq '.key')" | jq -c)
                    blueprint_assignment_count=$(echo $blueprint_assignment_list | jq -r "[.[] | select(.name == \"$(_jq_assignment '.name')\")] | length ")
                    if [ $blueprint_assignment_count -lt 1 ]; then
                        break;
                    fi
                    
                    check_bp_delete_if_failed "$(_jq '.key')"  "$(_jq_assignment '.name')" "${blueprint_assignment_list}"
                    sleep 1
                done            
            done
        fi
        
        if [ $skip_all_delete -eq 0 ] && [ $skip_policy_delete -eq 0 ]; then
            for row_delete_policy in $(echo "${delete_policies}" | jq -r '. [] | @base64'); do
                _jq_delete_policy(){
                    echo ${row_delete_policy} | base64 --decode | jq -r ${1}
                }
                
                echo "Deleting Policy - $(_jq_delete_policy '.name')"
                az policy assignment delete --subscription "$(_jq '.key')" --name "$(_jq_delete_policy '.name')" &
                
            done

            echo ""
            # az policy assignment list --subscription "$(_jq '.key')" | jq  -r ".[].displayName"
        fi    
    done

    if [ $skip_assignment_file_creation -eq 0 ]; then
        echo "${subscription_blueprint_assignment}" > "${existing_assignments_file}"
        echo "assignment saved to: ${existing_assignments_file}"
    fi
fi

if [ -f "${existing_assignments_file}" ] && [ $run_assignment_creation -eq 1 ]; then
    subscription_blueprint_assignment=$(cat "${existing_assignments_file}")

    for row in $(echo ${subscription_blueprint_assignment} | jq -r '. | keys | .[] | @base64'); do
        local_subscription_id=$(echo ${row} | base64 --decode)
        _jq(){
            echo "${subscription_blueprint_assignment}" | jq -rc ".\"${local_subscription_id}\".\"$1\""
        }
        blueprint_assignment_list=$(az blueprint assignment list --subscription "${local_subscription_id}" | jq -c)
        
        for row_assignment in $(echo "$(_jq 'assignment')" | jq -r '. [] | @base64'); do
            _jq_assignment(){
                echo "${row_assignment}" | base64 --decode | jq -r ${1}
            }
            
            # blueprintNameId_split=$(echo "$(_jq_assignment '.blueprintNameId_split')" | jq -rc ".[(. | length) - 1]=\"v1.0\"")
            # blueprintId=$(echo "${blueprintNameId_split}" | jq -rc ". | join(\"/\")")
            blueprintId=$(_jq_assignment '.blueprintId')
            blueprint_parameters=$(echo $(_jq_assignment '.parameters') | jq -rc ".")
            
            blueprint_assignment_count=$(echo $blueprint_assignment_list | jq -r "[.[] | select(.name == \"$(_jq_assignment '.name')\")] | length ")
            if [ $blueprint_assignment_count -lt 1 ]; then
                echo $blueprintId
                assign_bp_subscription "${local_subscription_id}" "$(_jq_assignment '.name')" "$(_jq_assignment '.location')" "${blueprintId}" "${blueprint_parameters}" "$(_jq_assignment '.identity')"
                continue
            fi
            provisioningState=$(echo $blueprint_assignment_list | jq -r "[.[] | select(.name == \"$(_jq_assignment '.name')\")] | .[0].provisioningState | ascii_downcase")
            if [ $blueprint_assignment_count -gt 0 ] && [ "${provisioningState}" == "succeeded" ]; then
                continue
            fi
            
            if [ $blueprint_assignment_count -gt 0 ]; then
                check_bp_delete_if_failed "${local_subscription_id}" "$(_jq_assignment '.name')" "${blueprint_assignment_list}"
                blueprint_assignment_list=$(az blueprint assignment list --subscription "${local_subscription_id}" | jq -c)
            fi            
            
            assign_bp_subscription "${local_subscription_id}" "$(_jq_assignment '.name')" "$(_jq_assignment '.location')" "${blueprintId}" "${blueprint_parameters}" "$(_jq_assignment '.identity')"

            

        done

    done
fi
