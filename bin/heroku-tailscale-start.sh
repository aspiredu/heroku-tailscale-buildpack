#!/usr/bin/env bash

set -e

function log() {
  echo "-----> $*"
}

function indent() {
  sed -e 's/^/       /'
}

if [ -z "$TAILSCALE_AUTH_KEY" ]; then
  log "Skipping Tailscale"

else
  log "Starting Tailscale"

  if [ -z "$TAILSCALE_HOSTNAME" ]; then
    if [ -z "$HEROKU_APP_NAME" ]; then
      tailscale_hostname=$(hostname)
    else
      # Only use the first 8 characters of the commit sha.
      # Swap the . in the dyno with a - since tailscale doesn't
      # allow for periods.
      tailscale_hostname=${HEROKU_SLUG_COMMIT:0:8}"-"${DYNO//./-}"-$HEROKU_APP_NAME"
    fi
  else
    tailscale_hostname="$TAILSCALE_HOSTNAME"
  fi
  log "Using Tailscale hostname=$tailscale_hostname"

  tailscaled -verbose ${TAILSCALED_VERBOSE:-0} --tun=userspace-networking --socks5-server=localhost:1055 &
  until tailscale up \
    --authkey=${TAILSCALE_AUTH_KEY} \
    --hostname="$tailscale_hostname" \
    --accept-dns=${TAILSCALE_ACCEPT_DNS:-true} \
    --accept-routes=${TAILSCALE_ACCEPT_ROUTES:-true} \
    --advertise-exit-node=${TAILSCALE_ADVERTISE_EXIT_NODE:-false} \
    --shields-up=${TAILSCALE_SHIELDS_UP:-false}
  do
    log "Waiting for 5s for Tailscale to start"
    sleep 5
  done

  export ALL_PROXY=socks5://localhost:1055/
  log "Tailscale started"
fi
