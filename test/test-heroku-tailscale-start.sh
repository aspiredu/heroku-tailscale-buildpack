#!/usr/bin/env bash

. utils.sh

function tailscaled() {
  echo ">>> mocked tailscaled -verbose ${TAILSCALED_VERBOSE:-0} call <<<"
}

export -f tailscaled


function tailscale() {
  # Sleep to allow tailscaled to finish processing in the
  # background and avoid flapping tests.
  sleep 0.01
  echo ">>> mocked tailscale call
--authkey=${TAILSCALE_AUTH_KEY}
--hostname=${TAILSCALE_HOSTNAME:-test}
--accept-dns=${TAILSCALE_ACCEPT_DNS:-true}
--accept-routes=${TAILSCALE_ACCEPT_ROUTES:-true}
--advertise-exit-node=${TAILSCALE_ADVERTISE_EXIT_NODE:-false}
--shields-up=${TAILSCALE_SHIELDS_UP:-false}
<<<"
}

export -f tailscale


run_test sanity heroku-tailscale-start.sh
TAILSCALED_VERBOSE=1 \
  TAILSCALE_AUTH_KEY="ts-auth-test" \
  TAILSCALE_HOSTNAME="test-host" \
  TAILSCALE_ACCEPT_DNS="false" \
  TAILSCALE_ACCEPT_ROUTES="false" \
  TAILSCALE_ADVERTISE_EXIT_NODE="true" \
  TAILSCALE_SHIELDS_UP="true" \
  run_test envs heroku-tailscale-start.sh

TAILSCALED_VERBOSE=1 \
  TAILSCALE_AUTH_KEY="ts-auth-test" \
  HEROKU_APP_NAME="heroku-app" \
  DYNO="another_web.1" \
  HEROKU_SLUG_COMMIT="hunter20123456789"\
  TAILSCALE_ACCEPT_DNS="false" \
  TAILSCALE_ACCEPT_ROUTES="false" \
  TAILSCALE_ADVERTISE_EXIT_NODE="true" \
  TAILSCALE_SHIELDS_UP="true" \
  run_test hostname heroku-tailscale-start.sh