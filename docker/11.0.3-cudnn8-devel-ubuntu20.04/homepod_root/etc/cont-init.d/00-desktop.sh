#!/usr/bin/with-contenv bash

set -eu
set -o pipefail

s6-setuidgid $DEEPVAC_USER mkdir -p "$HOME/Desktop"
