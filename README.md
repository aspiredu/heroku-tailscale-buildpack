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
heroku run -- heroku-tailscale-test.sh
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

The following settings are for the compile process for the buildpack. If you change these, you must
trigger a new build to see the change. Simply changing the environment variables in Heroku will not
cause a rebuild. These are all optional and will default to the latest values.

- ``TAILSCALE_BUILD_TS_VERSION`` - The target version Tailscale package.
- ``TAILSCALE_BUILD_TS_TARGETARCH`` - The target architecture for the Tailscale package.
- ``TAILSCALE_BUILD_PROXYCHAINS_REPO`` - The repository to install the proxychains-ng library from.

### Customizing proxychains.conf

If you decide you want to customize the ``proxychains.conf`` configuration file, you can copy the
file from conf into your project. If you copy it to the base directory of your application,
ProxyChains will find it automatically. If you copy it to a specific directory, such as conf,
you'll need to specify the path.

For example, if your conf file exists at ``<project>/conf/proxychains.conf`` your web command
would need to be:

```shell
proxychains4 -f conf/proxychains.conf <process>
```

## Deployment considerations

Switching to a Tailscale database or service can be troublesome. Especially if you interact
with the resource during the [Release phase of Heroku's deployments](https://devcenter.heroku.com/articles/release-phase)
such as basic SQL migrations. This is because you don't want to use the ``proxychains4``
wrapper if you don't have Tailscale running, and you can't have Tailscale running if you
don't have a valid Tailscale auth key and the database/resource configured in your tailnet.

I suggest working these problems out in reverse allowing for a fallback to a connection
outside of your tailnet. Once you've done the final switch over, you can remove access
to your database/resource from outside of the tailnet.

1. Configure database/resource to be accessible in and outside of your tailnet
2. Create a Tailscale auth key (reusuable[^1], not ephemeral, and appropriately tagged)
3. Add the auth key and the Tailscale database/resource url to your Heroku app's environment variables.

```shell
heroku config:set TAILSCALE_AUTH_KEY=<tailscale_auth_key> \
    TAILSCALE_DATABASE_URL=<tailscale_database_url>
```

4. Add the heroku-tailscale-buildpack

```shell
heroku buildpacks:add https://github.com/aspiredu/heroku-tailscale-buildpack
```

5. (Optional) Test your integration.
    1. Add the [Tailscale test machine in your tailnet](https://tailscale.com/kb/1073/hello/?q=test)
    2. Create a test tag that can only access the hello.ts.net machine via your ACLs
    3. Create a reusable ephemeral auth token that has the test tag applied to it.
    4. Temporarily change your application to use the test auth key.
    5. Trigger a build. This should include this buildpack.
    6. Run a one-off dyno to confirm that the setup is correct.

    ```shell
    heroku run heroku-tailscale-start.sh
    ```
    7. Restore the previous version of Tailscale auth key.

6. Modify your application to try to use the Tailscale database/resource and fallback to
   the non-tailnet version. If you're using python, the following script may help:

```python
import os
import dj_database_url

def tailscale_resource_key(base_key):
    """Fetch the resource key for a Tailscale service.

    It checks for an environment variable with the TAILSCALE_ prefix
    and if it exists and TAILSCALE_AUTH_KEY is defined, it uses that key.
    Else it returns the value that was passed in.

    This is useful for configuring different services to use tailscale
    without having to do everything all at once.
    """
    tailscale_auth_key = "TAILSCALE_AUTH_KEY"
    tailscale_resource_key = f"TAILSCALE_{base_key}"
    return (
        tailscale_resource_key
        if os.environ.get(tailscale_resource_key) and os.environ.get(tailscale_auth_key)
        else base_key
    )

DATABASES = {
    "default": dj_database_url.config(env=tailscale_resource_key("DATABASE_URL"))
}
```
7. Push your code to your Heroku application, triggering a new build.

```shell
git push heroku
```
8. You're now running your application connecting to your resources via Tailscale.

[^1]: You want reusable auth keys here because it will be used across all of your dynos
      in the application.

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

### CI TailScale auth koken

Eventually the GitHub ``TAILSCALE_TEST_AUTH_KEY`` will expire (every 90 days).
When that happens a new token will need to be generated. It should be reusable,
ephemeral and have the ``tag:test`` tag applied to it. It will need to be copied
to the ``TAILSCALE_TEST_AUTH_KEY`` repository secret for this repo.
