#!/bin/bash
# Delete an item (moves to trash)
# Usage: delete-item.sh <id> [--permanent]

set -e

if [ -z "$1" ]; then
    echo "Usage: delete-item.sh <id> [--permanent]" >&2
    exit 1
fi

ID="$1"

if [ "$2" = "--permanent" ]; then
    bw delete item "$ID" --permanent
else
    bw delete item "$ID"
fi
