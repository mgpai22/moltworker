#!/bin/bash
# Get password for a site/service
# Usage: get-password.sh <name>

set -e

if [ -z "$1" ]; then
    echo "Usage: get-password.sh <name>" >&2
    exit 1
fi

bw get password "$1" --raw
