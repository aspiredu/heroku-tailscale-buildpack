# Heroku buildpack to use Tailscale on Heroku

Run [Tailscale](https://tailscale.com/) on a Heroku dyno.

This is based on https://tailscale.com/kb/1107/heroku/.

Thank you to @rdotts, @kongmadai, @mvisonneau for their work on tailscale-docker and tailscale-heroku.

## Usage

Example usage:

    $ heroku buildpacks:add https://github.com/aspiredu/heroku-tailscale-buildpack
    Buildpack added. Next release on test-app will use aspiredu/heroku-tailscale-buildpack.
    Run `git push heroku main` to create a new release using this buildpack.

    $ git push heroku main
    ...

## Configuration

The following settings are available for configuration via environment variables:

- ``TAILSCALE_ACCEPT_DNS`` - Accept DNS configuration from the admin console. Defaults 
  to accepting DNS settings.
- ``TAILSCALE_ACCEPT_ROUTES`` - Accept subnet routes that other nodes advertise. Linux devices 
  default to not accepting routes. Defaults to accepting.
- ``TAILSCALE_ADVERTISE_EXIT_NODES`` - Offer to be an exit node for outbound internet traffic 
  from the Tailscale network. Defaults to not advertising.
- ``TAILSCALE_ADVERTISE_TAGS`` - Give tagged permissions to this device. You must be listed in 
  \"TagOwners\" to be able to apply tags. Defaults to none.
- ``TAILSCALE_AUTH_KEY`` - Provide an auth key to automatically authenticate the node as your 
  user account. **This must be set.**
- ``TAILSCALE_HOSTNAME`` - Provide a hostname to use for the device instead of the one provided 
  by the OS. Note that this will change the machine name used in MagicDNS. Defaults to the 
  hostname of the application (a guid)
- ``TAILSCALE_SHIELDS_UP"`` - Block incoming connections from other devices on your Tailscale 
  network. Useful for personal devices that only make outgoing connections. Defaults to off.
- ``TAILSCALED_VERBOSE`` - Controls verbosity for the tailscaled command. Defaults to 0.