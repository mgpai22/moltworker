#!/bin/bash
# Get an item by ID or name
# Usage: get-item.sh <id|name>

set -e

if [ -z "$1" ]; then
    echo "Usage: get-item.sh <id|name>" >&2
    exit 1
fi

bw get item "$1" --pretty
