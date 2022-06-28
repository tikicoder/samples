#!/bin/bash

tenant_id=""

subscription_exclude=""
subscription_filter=""

blueprint_exclude=""
blueprint_filter=""

skip_all_delete=0
skip_blueprint_delete=0
skip_policy_delete=0

skip_blueprint_assignment=0

generate_existing_assignments=0

existing_policies_tmp='[]'