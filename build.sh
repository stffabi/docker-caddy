#!/bin/bash

PROGNAME=$(basename $0)
IMAGE_NAME=$1

function error_exit
{
        echo "${PROGNAME}: ${1:-"Unknown Error"}" 1>&2
        exit 1
}

if [ "$1" = "" ]; then
  error_exit "Please provide image tag as first argument."
fi

OS=linux
ARCH=amd64
PLUGINS=cloudflare,digitalocean,dnsimple,dyn,gandi,googlecloud,namecheap,ovh,rfc2136,route53,vultr,linode

echo "Fetching Caddy..."
curl --silent --show-error --fail --location \
      --header "Accept: application/tar+gzip, application/x-gzip, application/octet-stream" -o - \
      "https://caddyserver.com/download/build?os=${OS}&arch=${ARCH}&features=${PLUGINS}" \
    | tar --no-same-owner -C ./ -xz caddy \
 && chmod 0755 caddy \
 && ./caddy -version

if [ "$?" != "0" ]; then
  error_exit "Unable to retrieve caddy."
fi

CADDY_VERSION=`./caddy -version`
echo "Fetched Caddy Version: $CADDY_VERSION"
VCS_REF=`git rev-parse --short HEAD`

if [ "$?" != "0" ]; then
   VCS_REF="NotAGitRepo"
fi

echo "Building Docker Image..."
docker build --build-arg BUILD_DATE=`date -u +"%Y-%m-%dT%H:%M:%SZ"` \
             --build-arg VCS_REF=$VCS_REF \
             --build-arg VERSION="$CADDY_VERSION - $PLUGINS" \
             --rm=false \
             -t $IMAGE_NAME \
             .

if [ "$2" == "" ]; then
  echo "Do not deploy."
  exit 0
fi

echo "Pushing $IMAGE_NAME..."
docker push $IMAGE_NAME

if [ "$2" != "release" ]; then
  echo "Do not publish as release version."
  exit 0
fi

push_docker() {
  echo "  -> push $1 $2..."
  docker tag $1 $2 || exit 1
  docker push $2 || exit 1
}

IMAGE_NAME_ONLY=${IMAGE_NAME%%:*}
if [ -z "$IMAGE_NAME_ONLY" ]
then
  echo "Unable to determine docker image name."
  exit 1
fi

SEMVER=${CADDY_VERSION##Caddy }
VERSION=`echo $SEMVER | awk '{split($0,a,"."); print a[1]}'`
BUILD=`echo $SEMVER | awk '{split($0,a,"."); print a[2]}'`
PATCH=`echo $SEMVER | awk '{split($0,a,"."); print a[3]}'`

if [ "${VERSION}" = "" ]; then
  echo "Please provide a semantic version."
  exit 1
fi

if [ "${BUILD}" = "" ]; then
  BUILD='0'
fi

if [ "${PATCH}" = "" ]; then
  PATCH='0'
fi

echo "Pushing $IMAGE_NAME_ONLY..."
push_docker $IMAGE_NAME             $IMAGE_NAME_ONLY:latest
push_docker $IMAGE_NAME_ONLY:latest $IMAGE_NAME_ONLY:$VERSION
push_docker $IMAGE_NAME_ONLY:latest $IMAGE_NAME_ONLY:$VERSION.$BUILD
push_docker $IMAGE_NAME_ONLY:latest $IMAGE_NAME_ONLY:$VERSION.$BUILD.$PATCH
