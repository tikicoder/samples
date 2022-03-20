ARG base_version="latest"
FROM alpine:${base_version}

ENV PATH="/opt/venv/bin:$PATH"

# any ca files that should be copied should be added here if they can be stored in a repo
COPY ./ca_certs/private/. /tmp/certs/private/ 
COPY ./ca_certs/public/. /tmp/certs/public/

COPY ./scripts/. /tmp/scripts/ 

RUN /bin/sh /tmp/scripts/init.sh

RUN rm -Rf /tmp/scripts
