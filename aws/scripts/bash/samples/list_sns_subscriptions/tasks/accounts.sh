#!/bin/bash

account_ids=$(aws organizations list-accounts | jq -rc "[.Accounts[] | select(.Status == \"ACTIVE\") | {\"id\": .Id, \"name\": .Name} ]")
for row in $(echo "${account_ids}" | jq -r '.[] | @base64'); do
  account_id="$(parse_jq_decode $row '.id')"
  account_name="$(parse_jq_decode $row '.name')"
  
  echo "${account_name} - ${account_id}"
  aws --profile="${account_name}-GlobalAdmins" --region=us-east-1 sns list-subscriptions --query 'Subscriptions[?contains(@.Protocol, `email`)]'  | jq -r '.[] | .Endpoint + " - " + .SubscriptionArn + " - " + .TopicArn'


  echo ""
  echo ""

done
