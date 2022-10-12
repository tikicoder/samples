#!/bin/bash


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
      validate_flags $@
  fi
  
fi

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



#  az storage account list --subscription 54e65ba5-a514-4972-814d-5fc21eba3b95 -o json | jq --arg filter_regex "^stnonprodgrplatform$" --argjson arr "[]" -rc "[ .[] | select(.sku.name|test(\"(.*)_((GRS)|(RAGRS)|(ZRS)|(LRS))$\", \"is\")) | select(.name|test(\"\$filter_regex\", \"is\"))  ] | \$arr + . "