## Unreleased

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
