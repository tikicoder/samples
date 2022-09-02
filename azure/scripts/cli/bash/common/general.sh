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