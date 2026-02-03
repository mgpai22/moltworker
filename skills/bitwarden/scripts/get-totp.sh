#!/bin/bash
# Get TOTP code for a site/service
# Usage: get-totp.sh <name>

set -e

if [ -z "$1" ]; then
    echo "Usage: get-totp.sh <name>" >&2
    exit 1
fi

bw get totp "$1" --raw
