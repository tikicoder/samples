
git clone https://github.com/tfutils/tfenv.git /root/.tfenv
ln -s /root/.tfenv/bin/* /usr/local/bin


# Azure CLI installer
# https://github.com/Azure/azure-cli/blob/dev/Dockerfile

apk add --no-cache bash openssh ca-certificates jq curl openssl perl git zip \
 && apk add --no-cache --virtual .build-deps gcc make openssl-dev libffi-dev musl-dev linux-headers \
 && apk add --no-cache libintl icu-libs libc6-compat \
 && apk add --no-cache bash-completion \
 && update-ca-certificates