#!/bin/bash
set -e

##
# Pre-requirements:
# - env FUZZER: path to fuzzer work dir
##

git clone --depth 1 https://github.com/google/honggfuzz.git "$FUZZER/repo"
