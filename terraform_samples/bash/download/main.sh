#!/bin/bash
set -e

#!/bin/bash
if [ ! $(command -v "realpath") ]; then
    realpath() {
    OURPWD=$PWD
    cd "$(dirname "$1")"
    LINK=$(readlink "$(basename "$1")")
    while [ "$LINK" ]; do
        cd "$(dirname "$LINK")"
        LINK=$(readlink "$(basename "$1")")
    done
    REALPATH="$PWD/$(basename "$1")"
    cd "$OURPWD"
    echo "$REALPATH"
    }
fi

full_path=$(realpath $0)
dir_path=$(dirname $full_path)
parent_path=$(realpath "${dir_path}/../")

source "${dir_path}/bash_functions/defaults_variables.sh"
source "${dir_path}/bash_functions/validate_flags.sh"

# usage="${0} work in progress"
# while getopts ":terraform-os:terraform-arch:terraform-save:terraform-version:default" o; do
#     case "${o}" in
#         terraform-os)
#             terraformOS=${OPTARG}
#             ;;
#         terraform-arch)
#             terraformARCH=${OPTARG}
#             ;;
#         *)
#             usage
#             ;;
#     esac
# done

echo "Config data"
echo "terraform-os: ${terraformOS}"
echo "terraform-arch: ${terraformARCH}"
echo "terraform-save: ${terraform_savePath}"
echo "terraform-download: ${terraform_download}"
echo "terraform-version: ${terraform_version} (Empty is default and latest version)"
echo "default: ${terraform_set_default}"

function UpdateSymLink() {
   terraformBinPath="${HOME}/.local/bin/terraform"
   if [ ! -f "${terraformBinPath}" ]; then
    ln -s $1 $terraformBinPath
   else
    if [ $terraform_set_default -lt 1 ]; then
        return
    fi

    rm $terraformBinPath
    ln -s $1 $terraformBinPath
   fi
   
   echo "SymLink Updated - (${1}:$terraformBinPath)"

}


terraformBuilds=$(curl -sL "https://releases.hashicorp.com/terraform/index.json" | \
    jq -r ".versions[].builds[] | select((.os==\"${terraformOS}\") and (.arch==\"${terraformARCH}\") and (.url|test(\"alpha|beta|rc\")|not))")

if [ -z "$terraform_version" ]; then
    terraform_version=$(echo $terraformBuilds | jq -r ".version" | sort -t. -k 1,1n -k 2,2n -k 3,3n -k 4,4n | tail -n1)
fi

if [ ! -d "${terraform_savePath}" ]; then
    mkdir -p $terraform_savePath
fi

if [ ! -d "${terraform_download}" ]; then
    mkdir -p $terraform_download
fi

terraform_local_path="${terraform_savePath}/terraform.${terraform_version}"
echo "Terraform local path ${terraform_local_path}"



if [ -f "${terraform_local_path}" ]; then

    if [ $terraform_set_default -eq 1 ]; then
    	UpdateSymLink $terraform_local_path
    fi

    echo "version already downloaded"
    exit;
fi

terraformBuild=$(echo $terraformBuilds | jq -r ". | select(.version==\"${terraform_version}\")")
terraformLatestURL=$(echo $terraformBuild | jq -r ".url")

echo $terraform_local_path

curl -s "$terraformLatestURL" -o "${terraform_download}/terraform.zip"

unzip "${terraform_download}/terraform.zip" -d "${terraform_download}/new"

mv "${terraform_download}/new/terraform" "${terraform_local_path}"
rm -Rf $terraform_download

chmod 755 $terraform_local_path

UpdateSymLink $terraform_local_path


