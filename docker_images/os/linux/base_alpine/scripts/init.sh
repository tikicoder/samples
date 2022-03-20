apk update \
    && apk upgrade 2>/dev/null || true

apk add zip unzip python3 bash curl openssh \
    && apk add --no-cache \
        ca-certificates 

update-ca-certificates 2>/dev/null \
    && mkdir -p /usr/local/share/ca-certificates

python3 -m venv /opt/venv \
    && python3 -m ensurepip \
    && python3 -m pip install --upgrade pip \
    && python3 -m pip install certifi

mv /tmp/certs/private/* /usr/local/share/ca-certificates/ 2>/dev/null\
    && mv /tmp/certs/public/* /usr/local/share/ca-certificates/ 2>/dev/null\
    && update-ca-certificates --fresh 2>/dev/null || true \
    && rm -Rf /tmp/certs/

cat /usr/local/share/ca-certificates/* >> $(python3 -m certifi)