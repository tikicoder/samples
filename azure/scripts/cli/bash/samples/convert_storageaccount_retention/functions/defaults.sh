#!/bin/bash

dry_run=0
apply_delete=0
tenant_id=""

subscription_exclude=""
subscription_filter=""

test_subscription_id=''

filter_storageaccount_currentreplication="(.*)_((GRS)|(RAGRS)|(ZRS)|(LRS))$"
storageaccount_newreplication="LRS"

filter_storageaccount_names='[]'
