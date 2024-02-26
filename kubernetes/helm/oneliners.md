# This is a random list of oneliners or simple scripts that I need to organize

### Delete all helm pages that match a particular string

#### Bash
helm list -A | grep "replace_with_string" | awk -F' ' '{print $1}' | while read ns; do helm uninstall -n $ns $ns; done

helm list -A -o json | jq -rc ".[] | select(.name | ascii_downcase | startswith(\"replace_with_string\")) | .name" | while read ns; do helm uninstall -n $ns $ns; done

#### Uninstall all platform packages
helm list -A -o json | jq -rc ".[] | select((.namespace | ascii_downcase) | startswith(\"platform-\")) | {name: .name, namespace:.namespace}" | while read -r chart; do echo "Package $(echo $chart | jq -r ".name") - $(echo $chart | jq -r ".namespace")"; helm uninstall -n "$(echo $chart | jq -r ".namespace")" "$(echo $chart | jq -r ".name")"  done

#### Powershell v7+
helm list -A -o json | ConvertFrom-Json -Depth 10 | ForEach-Object {if(($_.name -ilike 'replace_with_string-*')){ helm uninstall -n $_.name $_.name }}

helm list -A -o json | jq -rc ".[] | select(.name | ascii_downcase | startswith(`"replace_with_string`")) | .name" | ForEach-Object {helm uninstall -n $_ $_}

#### Uninstall all platform packages
helm list -A -o json | ConvertFrom-Json -Depth 10 | Where-Object {$_.namespace.toLower().StartsWith("platform-")} | ForEach-Object { helm uninstall -n $_.namespace $_name}