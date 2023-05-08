#!/bin/bash

dry_run=0
tenant_id=""

# https://learn.microsoft.com/en-us/azure/azure-resource-manager/management/request-limits-and-throttling#remaining-requests
default_remaining_request_headers="x-ms-ratelimit-remaining-subscription-reads"
# default_remaining_request_headers="$(echo $(cat <<-EOM
# x-ms-ratelimit-remaining-subscription-deletes,x-ms-ratelimit-remaining-subscription-reads,x-ms-ratelimit-remaining-subscription-writes,
# x-ms-ratelimit-remaining-tenant-reads,x-ms-ratelimit-remaining-tenant-writes,x-ms-ratelimit-remaining-subscription-resource-requests,
# x-ms-ratelimit-remaining-subscription-resource-entities-read,x-ms-ratelimit-remaining-tenant-resource-requests,x-ms-ratelimit-remaining-tenant-resource-entities-read
# EOM
# ))"

subscription_exclude=""
subscription_filter=""
test_subscription_id=''

remaining_request_headers=""
