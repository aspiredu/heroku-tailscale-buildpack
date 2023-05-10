ARG BASE_IMAGE
FROM $BASE_IMAGE

ARG STACK
RUN mkdir -p /app /cache /env
COPY . /buildpack
# Sanitize the environment seen by the buildpack, to prevent reliance on
# environment variables that won't be present when it's run by Heroku CI.
RUN env -i PATH=$PATH HOME=$HOME STACK=$STACK /buildpack/bin/detect /app
RUN env -i PATH=$PATH HOME=$HOME STACK=$STACK /buildpack/bin/compile /app /cache /env

# Install test utililties
RUN apt-get update && apt-get install -y curl

WORKDIR /app
