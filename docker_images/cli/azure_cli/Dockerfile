ARG cli_version="latest"
FROM mcr.microsoft.com/azure-cli:${cli_version}

RUN apk update \
    && apk upgrade \
    && apk add --no-cache \
        ca-certificates \
    && update-ca-certificates 2>/dev/null || true \
    && mkdir -p /usr/local/share/ca-certificates

# any ca files that should be copied should be added here if they can be stored in a repo
COPY ./ca_certs/private/* /usr/local/share/ca-certificates/
COPY ./ca_certs/public/* /usr/local/share/ca-certificates/

RUN update-ca-certificates --fresh 2>/dev/null || true 
RUN cat /usr/local/share/ca-certificates/* >> $(python -m certifi)

run echo "if [ \$(grep -ic \"8.8.8.8\" /etc/resolv.conf) -lt 1 ]; then echo 'nameserver 8.8.8.8' >> /etc/resolv.conf; fi" > /root/.bashrc

# ENTRYPOINT ["/usr/local/bin/az"]