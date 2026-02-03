#!/bin/bash
# Create a file Send for secure sharing
# Usage: send-file.sh <file> [--name <name>] [--password <pw>] [--maxAccessCount <n>]

set -e

if [ -z "$1" ]; then
    echo "Usage: send-file.sh <file> [options]" >&2
    exit 1
fi

FILE="$1"
shift

bw send -f "$FILE" "$@"
