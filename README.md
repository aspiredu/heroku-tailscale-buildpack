# Heroku buildpack to use Tailscale on Heroku

Run [Tailscale](https://tailscale.com/) on a Heroku dyno, shoving connections through proxychains.

## Why is proxychains necessary?

It really shouldn't be. However, I discovered that in my project to use Django and PostgreSQL,
pyscopg did not respect the ``ALL_PROXY`` environment variable. In order to get the network
communication to go through the Tailscale SOCKS5 proxy, I needed to manually force it. Enter
proxychains-ng.

This is based on https://tailscale.com/kb/1107/heroku/.

Thank you to @rdotts, @kongmadai, @mvisonneau for their work on tailscale-docker and tailscale-heroku.

## Usage

To set up your Heroku application, add the buildpack and ``TAILSCALE_AUTH_KEY``
environment variable:

    $ heroku buildpacks:add https://github.com/aspiredu/heroku-tailscale-buildpack
    Buildpack added. Next release on test-app will use aspiredu/heroku-tailscale-buildpack.
    Run `git push heroku main` to create a new release using this buildpack.

    $ heroku config:set TAILSCALE_AUTH_KEY="..."
    $ git push heroku main
    ...

To have your processes connect through the Tailscale proxy, you need to update your
``Procfile``. Here's an example for a Django project with a Celery worker:

```
web: proxychains4 -f vendor/proxychains-ng/conf/proxychains.conf uvicorn --host 0.0.0.0 --port "$PORT" myproject.project.asgi:application
worker: proxychains4 -f vendor/proxychains-ng/conf/proxychains.conf celery -A myproject.project worker
```

## Testing the integration

To test a connection, you can add the ``hello.ts.net`` machine into your network.
[Follow the instructions here](https://tailscale.com/kb/1073/hello/?q=testing). You
may need to modify your ACLs to allow access to the test machine. For example, I have
a separate Tailscale token that is tagged with ``tag:test``. My ACL looks like:

```json
{
  "hosts": {
      "hello-test": "100.101.102.103"
  },
  
  // Access control lists.
  "acls": [
      // Only allow the test tag to access anything.
      {"action": "accept", "src": ["tag:test"], "dst": ["hello-test:*"]}
  ]
}
```

To verify the connection works run:

```shell
heroku run -- heroku-start-tailscale.sh && proxychains4 -f vendor/proxychains-ng/conf/proxychains.conf curl hello.ts.net
```

You should see curl respond with ``<a href="https://hello.ts.net">Found</a>.``


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

The following settings are for the compile process for the buildpack. They are all optional
and will default to the latest values.

- ``TAILSCALE_BUILD_TS_VERSION`` - The target version Tailscale package.
- ``TAILSCALE_BUILD_TS_TARGETARCH`` - The target architecture for the Tailscale package.
- ``TAILSCALE_BUILD_PROXYCHAINS_REPO`` - The repository to install the proxychains-ng library from.

## Contributing

There are two different sets of tests to run. ``run_tests.sh`` does some basic
verification of the bin scripts. ``stack-test.sh`` spins up a Docker image with
Heroku's base image to verify the installation works locally. To run this second one,
you will need to create a Tailscale token that can connect to ``hello.ts.net``. See
[Tailscale's documentation on testing](https://tailscale.com/kb/1073/hello/?q=testing).

```shell
./run_tests.sh
source .env  # where TAILSCALE_TEST_AUTH_KEY should exist.
test/stack-test.sh heroku-22
```
