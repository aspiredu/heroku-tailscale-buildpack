#!/usr/bin/env bash

set -e

function log() {
  echo "-----> $*"
}

if [ -z "$TAILSCALE_AUTH_KEY" ]; then
  log "You need to add TAILSCALE_AUTH_KEY to your environment variables."
else
  log "Waiting to allow tailscale to finish set up."
  sleep 10
  log "Running `tailscale status` You should see your accessible machines on your tailnet."
  tailscale status

  log "Running `curl --socks5-hostname localhost:1055 hello.ts.net` "
  log 'Things are working if you see <a href="https://hello.ts.net">Found</a>.'
  curl --socks5-hostname localhost:1055 hello.ts.net
  log "If you didn't see the Found message, then you may need to add the hello.ts.net machine into your tailnet or configure your auth key to have access to it."
  log "Test complete. I hope you had your fingers crossed!"
fi
