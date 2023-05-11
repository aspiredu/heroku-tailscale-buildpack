# Contributing Guidelines

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

## CI TailScale auth token

Eventually the GitHub ``TAILSCALE_TEST_AUTH_KEY`` will expire (every 90 days).
When that happens a new token will need to be generated. It should be reusable,
ephemeral and have the ``tag:test`` tag applied to it. It will need to be copied
to the ``TAILSCALE_TEST_AUTH_KEY`` repository secret for this repo.

## Releasing updates

```shell
heroku plugins:install buildpack-registry

cd heroku-tailscale-buildpack
git checkout main
heroku buildpacks:publish aspiredu/heroku-tailscale-buildpack
```