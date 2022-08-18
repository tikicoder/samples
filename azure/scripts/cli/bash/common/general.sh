function output_test_color(){
  #this can be used to change the output color
  RED='\033[0;31m'
  NC='\033[0m' # No Color
  printf "${1}${NC}"
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