## Unreleased

* Update README to include mention of serving application to only users in your
  Tailnet.

## 1.1.1 (2023-06-15)

* Swap the ``_`` character for ``-`` in the hostname for 
  the DYNO environment variable.

## 1.1.0 (2023-06-15)

* Updated the default TAILSCALE_HOSTNAME to be ``[commit]-[dyno]-[appname]``.
  This requires [Heroku Labs runtime-dyno-metadata](https://devcenter.heroku.com/articles/dyno-metadata) to be enabled.

## 1.0.1 (2023-06-15)

* Added ``TAILSCALE_BUILD_EXCLUDE_START_SCRIPT_FROM_PROFILE_D`` build environment variable
  to control when the tailscale script starts.

## 1.0.1 (2023-06-13)

* Updated default tailscale version from 1.40.0 to 1.42.0

## 1.0.0 (2023-05-11)

* Implement buildpack sourcing ideas from
  https://github.com/moneymeets/python-poetry-buildpack,
  https://github.com/heroku/heroku-buildpack-pgbouncer and
  tailscale-docker and tailscale-heroku.
* Move the process to start tailscale into the .profile.d/ script.
* Only start Tailscale when the auth key is present in the environment 
  variables.
* Create a ``heroku-tailscale-test.sh`` script for easier testing/verification.
