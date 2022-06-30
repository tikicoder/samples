#!/bin/bash

# Possible option for display via progress bar instead of sub ids
# https://stackoverflow.com/questions/48251101/multiprocess-with-shared-variable-in-bash

accounts=$(az account list -o json)
account_data="{}"
agg_account_data="{}"


count=0
single_account_data="{}"
for row in $(echo "${accounts}" | jq -r '.[] | @base64'); do
  count=$((count+1))
  _jq() {
    echo ${row} | base64 --decode | jq -r ${1}
  }
  # az resource list | jq -r '. | group_by(.type)[] | {(.[0].type): ([.[]] | length)} ' | jq -s add
  echo "Processing Account $(_jq '.id')"
  if [ $(az resource list --subscription $(_jq '.id') | jq -r '. | length') -lt 1 ]; then
    continue;
  fi
  single_account_data=$(az resource list --subscription $(_jq '.id') | jq -r '. | group_by(.type)[] | {(.[0].type): ([.[]] | length)} ' | jq -s add | jq --sort-keys '.' | jq -r "{\"$(_jq '.id')\": .}")
  account_data=$((echo $account_data; echo $single_account_data) | jq -s add)


done
resource_types=$(echo $account_data | jq -r 'add | keys')

echo "Aggergating data"

for row in $(echo "${account_data}" | jq -r 'keys | .[] | @base64'); do
  _jq() {
    echo ${row} | base64 --decode 
  }
  
  for row_acct in $(echo "${account_data}" | jq -r ".\"$(_jq)\" | keys | .[] | @base64"); do
    _jq_acct() {
      echo ${row_acct} | base64 --decode 
    }

    agg_account_data_has_type=$(echo $agg_account_data | jq -r ". | has(\"$(_jq_acct)\") | tostring | ascii_downcase")
    account_type_count=$(echo $account_data | jq -r ".\"$(_jq)\".\"$(_jq_acct)\"")
    if [ "$agg_account_data_has_type" != "true" ]; then
      agg_account_data=$(echo ${agg_account_data} | jq -r ". | .\"$(_jq_acct)\"=${account_type_count}")
      continue
    fi
    existing_agg_account_type_count=$(echo $agg_account_data | jq -r ".\"$(_jq_acct)\"")
    agg_account_data=$(echo ${agg_account_data} | jq -r ". | .\"$(_jq_acct)\"=.\"$(_jq_acct)\" + ${account_type_count}")

  done
done

subscription_count=$(echo $account_data | jq -r '. | keys | length')
echo "Total account count : $subscription_count"
echo $account_data | jq -r '.'

agg_account_data=$(echo $agg_account_data | jq --sort-keys '.' | jq -r '.' )
   agg_account_data=$(echo ${agg_account_data} | jq -r ". | .\"subscription_count\"=${subscription_count}")
echo $agg_account_data | jq -r '.'


