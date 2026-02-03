#!/bin/bash
# Get username for a site/service
# Usage: get-username.sh <name>

set -e

if [ -z "$1" ]; then
    echo "Usage: get-username.sh <name>" >&2
    exit 1
fi

bw get username "$1" --raw
