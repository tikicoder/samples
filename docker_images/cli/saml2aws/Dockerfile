FROM alpine:latest

RUN apt-get update && \
    apt-get install -y ca-certificates curl && \
    rm -rf /var/lib/apt/lists/*


ENV SAML2AWS_VERSION_LATEST=$(curl -Ls https://api.github.com/repos/Versent/saml2aws/releases/latest | grep 'tag_name' | cut -d'v' -f2 | cut -d'"' -f1)

ENV SAML2AWS_DOWNLOAD_URL=https://github.com/Versent/saml2aws/releases/download/v${SAML2AWS_VERSION_LATEST}/saml2aws_${SAML2AWS_VERSION_LATEST}_linux_amd64.tar.gz

RUN mkdir -p /tmp/saml2aws

RUN cd /tmp/saml2aws && curl -L "$SAML2AWS_DOWNLOAD_URL" -o /tmp/saml2aws.tar.gz && \
    tar xvfz saml2aws.tar.gz && \
    mv saml2aws /usr/local/bin/saml2aws && \
    chmod +x /usr/local/bin/saml2aws && \
    cd /tmp && \
    rm -Rf /tmp/saml2aws

WORKDIR /saml2aws

RUN groupadd -g 10101 saml2aws && \
    useradd -u 10101 -g saml2aws saml2aws && \
    chown -R saml2aws:saml2aws /saml2aws
USER saml2aws:saml2aws

ENV HOME=/saml2aws
ENTRYPOINT [ "/usr/local/bin/saml2aws" ]