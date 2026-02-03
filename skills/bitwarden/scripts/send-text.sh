#!/bin/bash
# Create a text Send for secure sharing
# Usage: send-text.sh <text> [--name <name>] [--password <pw>] [--maxAccessCount <n>]

set -e

if [ -z "$1" ]; then
    echo "Usage: send-text.sh <text> [options]" >&2
    exit 1
fi

TEXT="$1"
shift

bw send "$TEXT" "$@"
