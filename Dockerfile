#
# Use abiosoft builder to build caddy from sources
#
FROM abiosoft/caddy:builder as builder

ARG CADDY_VERSION
ARG CADDY_PLUGINS

RUN VERSION=${CADDY_VERSION} PLUGINS=${CADDY_PLUGINS} ENABLE_TELEMETRY=false /bin/sh /usr/bin/builder.sh

#
# Alpine image to get some needed data
#
FROM alpine:latest as alpine

RUN apk add --no-cache \
    ca-certificates \
    tzdata

#
# Image
#
FROM scratch
MAINTAINER Fabrizio Steiner <stffabi@users.noreply.github.com>

ARG BUILD_DATE
ARG VCS_REF
ARG CADDY_VERSION
ARG CADDY_PLUGINS

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/stffabi/docker-caddy" \
      org.label-schema.version="$CADDY_VERSION - $CADDY_PLUGINS" \
      org.label-schema.schema-version="1.0"

ENV CADDYPATH /etc/caddy/assets

EXPOSE 80 443 2015
VOLUME /etc/caddy/

# copy files from other containers
COPY --from=alpine /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=alpine /usr/share/zoneinfo /usr/share/zoneinfo

COPY --from=builder /install/caddy /usr/bin/caddy

COPY etc/passwd /etc/passwd
ADD etc/caddy /etc/caddy

WORKDIR /usr/share/caddy/html
COPY index.html index.html

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["--conf", "/etc/caddy/Caddyfile", "--log", "stdout"]
