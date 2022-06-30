#example useage
#if [ $(IsNullOrEmptyResourceValue "_") -eq 1 ]; then
#    echo "good"
#fi
#

function IsNullOrEmptyResourceValue() {

    if [ -z "$1" ]; then
        echo  1;
        exit;
    fi

    trimData=$(echo $1 | sed -e 's/^[[:space:]]*//')

    if [ "$trimData" == "_" ]; then
        echo  1;
        exit;
    fi

    echo  0;
    exit;
    

}

function CheckForNull() {

    echo "\"${1}\"" | jq -r "if . != null and . != \"null\" and . != \"\" then . else \"_\" end"

}

function SkipDeployment() {

    resourcePREFIX=$1

    if [ -z "$resourcePREFIX" ]; then
        echo "##vso[task.logissue type=error]Resource Prefix is not defined"
        return;
    fi

    if [ -z "$TERRAFORM_DEPLOYMENT" ]; then
        echo "##vso[task.logissue type=error]TERRAFORM_DEPLOYMENT is not defined"
        return;
    fi

    TERRAFORMDEPLOYMENTLower=$(echo "$TERRAFORM_DEPLOYMENT" | tr '[:upper:]' '[:lower:]')
    RESOURCEPREFIXLower=$(echo "$resourcePREFIX" | tr '[:upper:]' '[:lower:]')

    KEYCHECK=$(echo $TERRAFORMDEPLOYMENTLower | jq -r "..|.key? | select(. == \"${RESOURCEPREFIXLower}\")")

    if [ "$KEYCHECK" != "$RESOURCEPREFIXLower"  ]; then
        echo "##vso[task.logissue type=warning]No deployment for ${resourcePREFIX}"
        return;
    fi

    Deployment=$(echo $TERRAFORMDEPLOYMENTLower | jq -r ".[] | select(.key == \"${RESOURCEPREFIXLower}\")")
    skipDeployment=$(echo $Deployment | jq -r 'if .skipDeployment then "true" else "false" end')

    if [ "$skipDeployment" == "true" ]; then
        echo "##vso[task.logissue type=warning]${resourcePREFIX} Deployment set to skip"
        return;
    fi

}