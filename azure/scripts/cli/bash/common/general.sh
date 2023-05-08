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

function is_bash_source {
  if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    echo 1
    return
  fi

  echo 0

}

if [ $(is_bash_source) -eq 1 ]; then
  general_full_path=$(realpath "${BASH_SOURCE[0]}")
else
  general_full_path=$(realpath "${0}")
fi
general_dir_path=$(dirname $general_full_path)
general_parent_path=$(realpath "${general_dir_path}/../")
general_root_path=$general_parent_path

if [ ! -z "${general_dir_path}" ]; then
  if [ -f "${general_dir_path}/defaults.sh" ]; then
    source "${general_dir_path}/defaults.sh"
  fi
  # this is done as a way to expand the script incase there is something that shouldn't be in the repo
  if [ -f "${general_dir_path}/defaults_variables_override.sh" ]; then
    source "${general_dir_path}/defaults_variables_override.sh"
  fi  
fi

function validate_flags(){
  # work on system to allow spaces in key values
  while [ -n "$1" ]; do # while loop starts
    echo "working on $1"
    case "$1" in    
      --dry-run) dry_run=1
      ;;
      --verbose) verbose=1
      ;;
      --apply) apply_general=1
      ;;
      --confirm) apply_confirm=1
      ;;
      --tenant-id=*) tenant_id=$(echo $1  | awk -F= '{print $2}')
      ;;
      --subscription-exclude=*) subscription_exclude=$(echo $1  | awk -F= '{print $2}')
      ;;        
      --subscription-filter=*) subscription_filter=$(echo $1  | awk -F= '{print $2}')
      ;;
      *)
        if [ "$(type -t validate_flags_custom)" ]; then
          validate_flags_custom "$1"
        fi
      ;;
    esac

    shift

  done

}

if [ ! -z "${dir_path}" ]; then
  if [ -f "${dir_path}/functions/defaults.sh" ]; then
    source "${dir_path}/functions/defaults.sh"
  fi
  # this is done as a way to expand the script incase there is something that shouldn't be in the repo
  if [ -f "${dir_path}/functions/defaults_variables_override.sh" ]; then
    source "${dir_path}/functions/defaults_variables_override.sh"
  fi

  if [ -f "${dir_path}/functions/validate_flags.sh" ]; then
    source "${dir_path}/functions/validate_flags.sh"
  fi
fi
validate_flags $@

function base_init(){
  

  if [ $dry_run -ne 0 ]; then
    echo "--dry-run flag set skipping all update/delete actions"
    apply_general=0
    apply_confirm=0
  fi

  if [ $apply_general -ne 0 ]; then
      echo "--apply flag set this will allow system to make changes"
  fi

  if [ $apply_confirm -ne 0 ]; then
      echo "--confirm flag set this will skip any confirm prompts"
  fi

  if [ ! -z "${tenant_id}" ]; then
      subscription_info=$(az account list --query "[?homeTenantId == '${tenant_id}']" | jq -r -c "[.[] | {(.id):.name}]")
  else
      subscription_info=$(az account list | jq -r -c "[.[] | {(.id):.name}]")
  fi

  subscription_info=$(echo $subscription_info | jq -r " [.[]  | to_entries | add]")

  if [ ! -z "${subscription_filter}" ]; then
      subscription_info=$(echo "${subscription_info}" | jq --argjson sub_include "$(split_string_jq "${subscription_filter}")" -rc "[.[] | select(.key | IN(\$sub_include[])) ]")
  fi

  if [ ! -z "${subscription_exclude}" ]; then
      subscription_info=$(echo "${subscription_info}" | jq --argjson sub_include "$(split_string_jq "${subscription_exclude}")" -rc "[.[] | select(.key | IN(\$sub_include[])) ]")
  fi

  if [ ! -z "${test_subscription_id}" ]; then
    subscription_info=$(echo "${subscription_info}" | jq -rc "[.[] | select(.key == \"$test_subscription_id\")]")
  fi
}

function output_test_color(){
  #this can be used to change the output color
  # https://dev.to/ifenna__/adding-colors-to-bash-scripts-48g4
  local RED='\033[0;31m'
  # alt red examples
  # '\e[31m' # \033 must be similar as \e 
  # 0; can be 0 - 4
  # 0 Reset/Normal
  # 1 Bold, 2 Faint, 3 Italics, 4 Underline

  local NC='\033[0m' # No Color
  eval echo -e "\"${1}${NC}\""
}
function parse_jq_decode(){
  raw_data=$1
  attribute=$2
  echo ${raw_data} | base64 --decode | jq -r ${attribute}
}

function parse_jq(){
  raw_data=$1
  attribute=$2
  echo ${raw_data} | jq -r ${attribute}
}

function split_string_jq(){
  str_value=$1
  str_split=",;\\\s"
  if [ $# -gt 1 ]; then
    str_split=$2
  fi

  echo $(echo "\"${str_value}\"" | jq -rc "[. | split(\"[${str_split}]\";\"ig\") | .[] | rtrimstr(\" \") | ltrimstr(\" \") | select(. != \"\")]")
}

function trim_string(){
  str_value=$1

  echo $(rtrim_string $(ltrim_string $str_value))
}

function ltrim_string(){
  str_value=$1

  echo $str_value | sed -e 's/^[[:space:]]*//' 
}

function rtrim_string(){
  str_value=$1

  echo $str_value |  sed -e 's/[[:space:]]*$//'
}

function base_subscription_get_resources() {
  
  local localbase_jq_unique_attr=".id"
  local localbase_resource_list=$1
  local localbase_filter_resource=$2
  local localbase_jq_statement_single=$3
  local localbase_jq_statement_multiple=$4
  local localbase_resources_return_list='[]'

  if [ -z "${localbase_resource_list}" ]; then
    echo $localbase_resources_return_list
    return
  fi

  if [ $(echo "${localbase_filter_resource}" | jq -r '. | length') -lt 1 ]; then
    localbase_resources_return_list=$(echo $localbase_resource_list | jq -rc "$localbase_jq_statement_single")
    echo $localbase_resources_return_list
    return
  fi

  for filter_regex in $(echo "${localbase_filter_resource}" | jq -r '.[]'); do
    localbase_resources_return_list=$(echo $localbase_resource_list | jq --arg filter_regex "${filter_regex}" --argjson arr "${localbase_resources_return_list}" -rc "$localbase_jq_statement_multiple")
  done
  localbase_resources_return_list=$(echo $localbase_resources_return_list | jq -rc "[ .[] | ${localbase_jq_unique_attr} ] | unique")
  localbase_resources_return_list=$(echo $localbase_resource_list | jq --argjson arr "${localbase_resources_return_list}" -rc "[ .[] | .id as \$ID | select(first(\$arr[]|select(. == \$ID)) != \"\") ]")

  echo $localbase_resources_return_list
}


# az storage account list --subscription 80e8fb02-f723-48d0-a4fe-54b1b445c8a5 -o json | jq --arg filter_regex "^livenxstoragegroup$" --argjson arr "[]" -rc "[ .[] | select(.sku.name|test(\"(.*)_((GRS)|(RAGRS)|(ZRS)|(LRS))$\", \"is\")) | .name | select(.|test(\$filter_regex, \"is\")) ]  "
#  az storage account list --subscription 54e65ba5-a514-4972-814d-5fc21eba3b95 -o json | jq --arg filter_regex "^stnonprodgrplatform$" --argjson arr "[]" -rc "[ .[] | select(.sku.name|test(\"(.*)_((GRS)|(RAGRS)|(ZRS)|(LRS))$\", \"is\")) | select(.name|test(\"\$filter_regex\", \"is\"))  ] | \$arr + . "