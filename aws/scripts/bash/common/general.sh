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

# Could update to use jq for the flags in the future
# Found this method in some Terraform work
# eval "$(jq -r '@sh "verbose=\(.verbose == true) environment=\(.environment) environment_tier=\(if .environment_tier == null then "" else .environment_tier end) json_path=\(.json_path) main_filename=\(.main_filename) override_directory=\(.override_directory)"')"
# then to run the script use
# echo '{"verbose":<true/false>, "environment": "<environment>", "environment_tier": "<environment_tier>", "json_path":"./processed", "override_directory": "./overrides", "main_filename": "values.yaml"}' | ./script.sh
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




