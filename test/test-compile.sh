#!/usr/bin/env bash

. utils.sh

run_test sanity-1 compile
run_test sanity-2 compile BUILD_DIR
run_test sanity-3 compile BUILD_DIR CACHE_DIR
