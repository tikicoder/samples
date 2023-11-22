# This is a random list of oneliners or simple scripts that I need to organize

### Delete all helm pages that match a particular string

#### Bash
helm list -A | grep "replace_with_string" | awk -F' ' '{print $1}' | while read ns; do helm uninstall -n $ns $ns; done

helm list -A -o json | jq -rc ".[] | select(.name | ascii_downcase | startswith(\"replace_with_string\")) | .name" | while read ns; do helm uninstall -n $ns $ns; done

#### Powershell v7+
helm list -A -o json | ConvertFrom-Json -Depth 10 | ForEach-Object {if(($_.name -ilike 'replace_with_string-*')){ helm uninstall -n $_.name $_.name }}

helm list -A -o json | jq -rc ".[] | select(.name | ascii_downcase | startswith(`"replace_with_string`")) | .name" | ForEach-Object {helm uninstall -n $_ $_}
