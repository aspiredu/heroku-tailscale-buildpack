# Heroku buildpack to use Tailscale on Heroku

Run [Tailscale](https://tailscale.com/) on a Heroku dyno.

## Usage

To set up your Heroku application, add the buildpack and `TAILSCALE_AUTH_KEY`
environment variable:

    $ heroku buildpacks:add https://github.com/sundaycarwash/heroku-buildpack-tailscale
    $ heroku config:set TAILSCALE_AUTH_KEY="..."

To have your processes connect through the Tailscale proxy, you need to use
the `socks5` proxy provided by `tailscaled`.

```
curl --socks5-hostname localhost:1055 <device-name>
```

```ruby
    TCPSocket.socks_server = "localhost"
    TCPSocket.socks_port = 1055
```

## Testing the integration

To test a connection, you can add the `hello.ts.net` machine into your network.
[Follow the instructions here](https://tailscale.com/kb/1073/hello/?q=testing). You
may need to modify your ACLs to allow access to the test machine. For example, I have
a separate Tailscale token that is tagged with `tag:test`. My ACL looks like:

```json
{
  "hosts": {
    "hello-test": "100.101.102.103"
  },

  // Access control lists.
  "acls": [
    // Only allow the test tag to access anything.
    { "action": "accept", "src": ["tag:test"], "dst": ["hello-test:*"] }
  ]
}
```

To verify the connection works run:

```shell
heroku run -- heroku-tailscale-test.sh
```

You should see curl respond with `<a href="https://hello.ts.net">Found</a>.`

## Configuration

The following settings are available for configuration via environment variables:

- `TAILSCALE_ACCEPT_DNS` - Accept DNS configuration from the admin console. Defaults
  to accepting DNS settings.
- `TAILSCALE_ACCEPT_ROUTES` - Accept subnet routes that other nodes advertise. Defaults
  to accepting subnet routes.
- `TAILSCALE_ADVERTISE_EXIT_NODES` - Offer to be an exit node for outbound internet traffic
  from the Tailscale network. Defaults to not advertising.
- `TAILSCALE_ADVERTISE_TAGS` - Give tagged permissions to this device. You must be listed in
  \"TagOwners\" to be able to apply tags. Defaults to none.
- `TAILSCALE_AUTH_KEY` - Provide an auth key[^1] to automatically authenticate the node as your
  user account. **This must be set.**
- `TAILSCALE_HOSTNAME` - Provide a hostname to use for the device instead of the one provided
  by the OS. Note that this will change the machine name used in MagicDNS. Defaults to the
  hostname of the application (a guid). If you have [Heroku Labs runtime-dyno-metadata](https://devcenter.heroku.com/articles/dyno-metadata)
  enabled, it defaults to `[commit]-[dyno]-[appname]`.
- `TAILSCALE_SHIELDS_UP"` - Block incoming connections from other devices on your Tailscale
  network. Useful for personal devices that only make outgoing connections. Defaults to off.
- `TAILSCALED_VERBOSE` - Controls verbosity for the tailscaled command. Defaults to 0.

The following settings are for the compile process for the buildpack. If you change these, you must
trigger a new build to see the change. Simply changing the environment variables in Heroku will not
cause a rebuild. These are all optional and will default to the latest values.

- `TAILSCALE_VERSION` - The Tailscale package version.

[^1]:
    You want reusable auth keys here because it will be used across all of your dynos
    in the application.
