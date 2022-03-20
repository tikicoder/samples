# AWS CLI alpine
# https://github.com/kyleknap/aws-cli/blob/source-proposal/proposals/source-install.md#alpine-linux
ARG base_version="latest"
ARG AZCLI_VERSION="latest"
ARG AWSCLI_VERSION="2.4.24"
ARG JP_VERSION="0.2.1"
FROM tiki/base_alpine:${base_version}

ENV AWSCLI_VERSION=${AWSCLI_VERSION}
RUN apk add --no-cache \
    curl \
    make \
    cmake \
    gcc \
    libc-dev \
    libffi-dev \
    openssl-dev \
    && curl https://awscli.amazonaws.com/awscli-${AWSCLI_VERSION}.tar.gz | tar -xz \
    && cd awscli-${AWSCLI_VERSION} \
    && ./configure --prefix=/opt/aws-cli/ --with-download-deps \
    && make \
    && make install




FROM tiki/base_alpine:${base_version}
RUN apk --no-cache add groff git
COPY --from=builder /opt/aws-cli/ /opt/aws-cli/

# https://github.com/tfutils/tfenv
RUN git clone https://github.com/tfutils/tfenv.git /root/.tfenv \
  && ln -s /root/.tfenv/bin/* /usr/local/bin



# Azure CLI installer
# https://github.com/Azure/azure-cli/blob/dev/Dockerfile

LABEL maintainer="Microsoft" \
  org.label-schema.schema-version="1.0" \
  org.label-schema.vendor="Microsoft" \
  org.label-schema.name="Azure CLI" \
  org.label-schema.version=$CLI_VERSION \
  org.label-schema.license="MIT" \
  org.label-schema.description="The Azure CLI is used for all Resource Manager deployments in Azure." \
  org.label-schema.url="https://docs.microsoft.com/cli/azure/overview" \
  org.label-schema.usage="https://docs.microsoft.com/cli/azure/install-az-cli2#docker" \
  org.label-schema.build-date=$BUILD_DATE \
  org.label-schema.vcs-url="https://github.com/Azure/azure-cli.git" \
  org.label-schema.docker.cmd="docker run -v \${HOME}/.azure:/root/.azure -it mcr.microsoft.com/azure-cli:$CLI_VERSION"

RUN apk add --no-cache bash openssh ca-certificates jq curl openssl perl git zip \
  && apk add --no-cache --virtual .build-deps gcc make openssl-dev libffi-dev musl-dev linux-headers \
  && apk add --no-cache libintl icu-libs libc6-compat \
  && apk add --no-cache bash-completion \
  && update-ca-certificates



RUN curl -L https://github.com/jmespath/jp/releases/download/${JP_VERSION}/jp-linux-amd64 -o /usr/local/bin/jp \
  && chmod +x /usr/local/bin/jp

RUN curl -L https://github.com/jmespath/jp/releases/download/${JP_VERSION}/jp-linux-amd64 -o /usr/local/bin/jp \
  && chmod +x /usr/local/bin/jp

WORKDIR azure-cli
COPY . /azure-cli

# 1. Build packages and store in tmp dir
# 2. Install the cli and the other command modules that weren't included
RUN ./scripts/install_full.sh \
 && cat /azure-cli/az.completion > ~/.bashrc \
 && runDeps="$( \
    scanelf --needed --nobanner --recursive /usr/local \
        | awk '{ gsub(/,/, "\nso:", $2); print "so:" $2 }' \
        | sort -u \
        | xargs -r apk info --installed \
        | sort -u \
    )" \
 && apk add --virtual .rundeps $runDeps

WORKDIR /

# Remove CLI source code from the final image and normalize line endings.
RUN rm -rf ./azure-cli && \
    dos2unix /root/.bashrc /usr/local/bin/az

ENV AZ_INSTALLER=DOCKER


CMD bash












ARG base_version="latest"
FROM tiki/base_alpine:${base_version}

ENV AWSCLI_VERSION=2.4.24

COPY ./scripts/. /tmp/scripts/ 

run /bin/bash /tmp/scripts/init.sh

RUN rm -Rf /tmp/scripts

# run echo "if [ \$(grep -ic \"8.8.8.8\" /etc/resolv.conf) -lt 1 ]; then echo 'nameserver 8.8.8.8' >> /etc/resolv.conf; fi" > /root/.bashrc

# ENTRYPOINT ["/usr/local/bin/az"]