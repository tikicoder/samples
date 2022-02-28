#!/bin/bash
skip_prompt=0

terraformOS="$(uname -s | awk '{print tolower($0)}')"
terraformARCH="$(uname -m)"

terraform_download="/tmp/terraform"
terraform_savePath="${HOME}/.local/bin"
terraform_version=""
terraform_set_default=0

if [[ $terraformARCH = *_64 ]]; then
    terraformARCH="amd64"
    
elif [[ $terraformARCH = x86_* ]]; then
    terraformARCH="386"
else
    terraformARCH="arm64"
fi