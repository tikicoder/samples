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


if [ $skip_all_delete -ne 0 ]; then
    echo "--skip-delete flag set skipping all delete"
fi

if [ $skip_blueprint_delete -ne 0 ]; then
    echo "--skip-delete-bp flag set skipping blueprint delete"
fi

if [ $skip_policy_delete -ne 0 ]; then
    echo "--skip-delete-policy flag set skipping policy delete"
fi

if [ $skip_blueprint_assignment -ne 0 ]; then
    echo "--skip-assignment flag set skipping assigning blueprints"
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
    
    subscription_policies=$(az policy assignment list --subscription "$(_jq '.key')" --query "[].{id: id, name: name, createdBy: metadata.createdBy, updatedBy: metadata.updatedBy}")
    delete_policies=$(echo "${subscription_policies}" | jq --argjson principal "${blueprint_assignment_principal}" -rc "[.[] | select((.createdBy | IN(\$principal[])) or select(.updatedBy | IN(\$principal[])))]")
    not_delete_policies=$(echo "${subscription_policies}" | jq --argjson principal "${blueprint_assignment_principal}" -rc "[.[] | select((.createdBy | IN(\$principal[]) | not) and select(.updatedBy | IN(\$principal[]) | not))]")

    subscription_blueprint_assignment=$(echo "${subscription_blueprint_assignment}" | jq -rc ". | .\"$(_jq '.key')\"={assignment: $blueprint_assignment, delete_policies:$delete_policies, not_delete_policies:$not_delete_policies}")
    
    # # Force Deleted extra policies
    # # Update the existing_policies_tmp with a json array of display names
    # # existing_policies_tmp is defined in the defaults.sh
    # delete_policies=$(az policy assignment list --subscription "$(_jq '.key')" | jq --argjson existing "${existing_policies_tmp}" -r "[.[] | select(.displayName | IN(\$existing[])) | .name]")
    # for row_delete_policy in $(echo "${delete_policies}" | jq -r '. [] | @base64'); do
    #     _jq_delete_policy(){
    #         echo ${row_delete_policy} | base64 --decode
    #     }
        
    #     echo "Deleting Policy Old - $(_jq_delete_policy)"

    #     az policy assignment delete --subscription "$(_jq '.key')" --name "$(_jq_delete_policy)" &
    # done
    # az policy assignment list --subscription "$(_jq '.key')" | jq  -r ".[].displayName"
    
    
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
                blueprint_assignment_count=$(az blueprint assignment list --subscription "$(_jq '.key')" | jq -r "[.[] | select(.name == \"$(_jq_assignment '.name')\")] | length ")
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

# echo "${subscription_blueprint_assignment}" > "existing_assignments.txt"

subscription_blueprint_assignment=$(cat "existing_assignments.txt")
if [ $skip_blueprint_assignment -eq 0 ]; then

    for row in $(echo ${subscription_blueprint_assignment} | jq -r '. | keys | .[] | @base64'); do
        local_subscription_id=$(echo ${row} | base64 --decode)
        _jq(){
            echo "${subscription_blueprint_assignment}" | jq -rc ".\"${local_subscription_id}\".\"$1\""
        }

        for row_assignment in $(echo "$(_jq 'assignment')" | jq -r '. [] | @base64'); do
            _jq_assignment(){
                echo ${row_assignment} | base64 --decode | jq -r ${1}
            }
            
            blueprintNameId_split=$(echo "$(_jq_assignment '.blueprintNameId_split')" | jq -rc ".[(. | length) - 1]=\"v1.0\"")
            blueprintId=$(echo "${blueprintNameId_split}" | jq -rc ". | join(\"/\")")
            # blueprintId=$(_jq_assignment '.blueprintId')
            blueprint_parameters=$(echo $(_jq_assignment '.parameters') | jq -rc ".")

            echo "Assigning Blueprint - ${local_subscription_id} - $(_jq_assignment '.name') - ${blueprintId}"
            az blueprint assignment create --subscription "${local_subscription_id}" --name \
                "$(_jq_assignment '.name')" --location "$(_jq_assignment '.location')" --identity-type UserAssigned \
                --blueprint-version "${blueprintId}" \
                --parameters "${blueprint_parameters}" \
                --user-assigned-identity "$(_jq_assignment '.identity')" \
                --locks-mode AllResourcesDoNotDelete &

        done

    done
fi
