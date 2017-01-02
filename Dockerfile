FROM centurylink/ca-certs
MAINTAINER Fabrizio Steiner <stffabi@users.noreply.github.com>

ARG BUILD_DATE
ARG VCS_REF
ARG VERSION

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/stffabi/docker-caddy" \
      org.label-schema.version="$VERSION" \
      org.label-schema.schema-version="1.0"

ENV CADDYPATH /etc/caddy/assets

EXPOSE 80 443 2015
VOLUME /etc/caddy/

COPY caddy /usr/bin/caddy
COPY etc/passwd /etc/passwd
ADD etc/caddy /etc/caddy

WORKDIR /usr/share/caddy/html
COPY index.html index.html

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["--conf", "/etc/caddy/Caddyfile", "--log", "stdout"]