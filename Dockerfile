FROM alpine:3.4
MAINTAINER stffabi <stffabi@users.noreply.github.com>

LABEL caddy_version="0.9.4" architecture="amd64"

ENV CADDYPATH /etc/caddy/assets

ARG plugins=cloudflare,digitalocean,dnsimple,dyn,gandi,googlecloud,namecheap,ovh,rfc2136,route53,vultr,linode

RUN apk add --no-cache openssh-client tar curl

RUN curl --silent --show-error --fail --location \
      --header "Accept: application/tar+gzip, application/x-gzip, application/octet-stream" -o - \
      "https://caddyserver.com/download/build?os=linux&arch=amd64&features=${plugins}" \
    | tar --no-same-owner -C /usr/bin/ -xz caddy \
 && chmod 0755 /usr/bin/caddy \
 && /usr/bin/caddy -version

EXPOSE 80 443 2015
VOLUME /etc/caddy/

ADD caddy /etc/caddy

WORKDIR /usr/share/caddy/html
COPY index.html index.html

ENTRYPOINT ["/usr/bin/caddy"]
CMD ["--conf", "/etc/caddy/Caddyfile", "--log", "stdout"]
