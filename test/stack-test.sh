#!/usr/bin/env bash

set -euo pipefail

[ $# -eq 1 ] || { echo "Usage: $0 STACK"; exit 1; }

if [ -z "${TAILSCALE_TEST_AUTH_KEY:-}" ] ; then
  echo "The environment variable TAILSCALE_TEST_AUTH_KEY must be set."
  exit 1;
fi

STACK="${1}"
BASE_IMAGE="heroku/${STACK/-/:}-build"
OUTPUT_IMAGE="heroku-tailscale-test-${STACK}"

echo "Building buildpack on stack ${STACK}..."

docker build \
  --platform linux/amd64 \
  --build-arg STACK="$STACK" \
  --build-arg BASE_IMAGE="$BASE_IMAGE" \
  -t "$OUTPUT_IMAGE" \
  .

LOAD_ENV_VARS="source .profile.d/heroku-tailscale-buildpack.sh && sleep 10"
PROXYCHAINS_WRAPPER="proxychains4 -f /app/vendor/proxychains-ng/conf/proxychains.conf"
TEST_TAILNET_CONNECTION="curl --connect-timeout 5 hello.ts.net"
TEST_COMMAND="$LOAD_ENV_VARS && $PROXYCHAINS_WRAPPER $TEST_TAILNET_CONNECTION"

docker run \
    --rm \
    --platform linux/amd64 \
    -e TAILSCALE_AUTH_KEY="$TAILSCALE_TEST_AUTH_KEY" \
    -t "$OUTPUT_IMAGE" \
  bash -c "$TEST_COMMAND" && \
  echo "Success"
