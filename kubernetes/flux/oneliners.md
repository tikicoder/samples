# This is a random list of oneliners or simple scripts that I need to organize

### reconcile failed helm releases

#### Bash
for item in $(flux get hr -A | grep -iv "\(^\(\s\)\+\)" | awk -F' ' '{printf "{\"namespace\":\"%s\",\"name\":\"%s\",\"ready\":%s}\n", $1,$2,tolower($5)}' | tail -n +2);
do
    namespace="$(echo $item | jq -r ".namespace")"
    name="$(echo $item | jq -r ".name")"
    ready="$(echo $item | jq -r ".ready")"
    if [ "$ready" != "true" ]; then
        echo "Force Reconcile ${name} - ${namespace}"
        flux reconcile hr --force -n $namespace $name         
    fi
done
