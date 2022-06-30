

# Subscription Count
az account list | jq -r '[.[] | {"id": .id, "tenantId": .tenantId}] | group_by(.tenantId) | map(.[0] + {"count": length}) | [ .[] | {"tenantId": .tenantId, "count": .count}]'