#!/usr/bin/env bash

set -e

echo "-----> tailscale-buildpack: Starting tailscale"

tailscaled -verbose ${TAILSCALED_VERBOSE:-0} --tun=userspace-networking --socks5-server=localhost:1055 &
until tailscale up \
  --authkey=${TAILSCALE_AUTH_KEY} \
  --hostname=${TAILSCALE_HOSTNAME:-$(hostname)} \
  --accept-dns=${TAILSCALE_ACCEPT_DNS:-true} \
  --accept-routes=${TAILSCALE_ACCEPT_ROUTES:-true} \
  --advertise-exit-node=${TAILSCALE_ADVERTISE_EXIT_NODE:-false} \
  --advertise-tags=${TAILSCALE_ADVERTISE_TAGS:-''} \
  --shields-up=${TAILSCALE_SHIELDS_UP:-false}
do
    echo "-----> tailscale-buildpack: waiting for 5s for tailscale to start"
    sleep 2
done

export ALL_PROXY=socks5://localhost:1055/
echo "-----> tailscale-buildpack: tailscale started"

