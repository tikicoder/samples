ARG alpine_version="latest"
FROM alpine:${alpine_version}

RUN rm -rf /var/cache/apk/* && \
    rm -rf /tmp/*

run cat /etc/resolv.conf > /etc/resolv.conf.bak && \
  first_nameserver=$(grep -i "nameserver" /etc/resolv.conf | head -1) && \
  printf "$([ $(grep -ic "nameserver 8.8.8.8" /etc/resolv.conf) -lt 1 ] && sed -e "/${first_nameserver}/i nameserver 8.8.8.8" /etc/resolv.conf)" > /etc/resolv.conf.tmp && \
  cat /etc/resolv.conf.tmp > /etc/resolv.conf && \
  rm /etc/resolv.conf.tmp

RUN apk update && apk -U upgrade && \
  apl add curl


ENV POETRY_HOME=/opt/poetry
RUN curl -sSL https://raw.githubusercontent.com/python-poetry/poetry/master/get-poetry.py | python -

ENV PATH=/opt/poetry/bin:$PATH
ENTRYPOINT ["/opt/poetry/bin/poetry"]