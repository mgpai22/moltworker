#!/bin/bash
# Receive a Bitwarden Send
# Usage: receive.sh <url> [--password <pw>] [--output <file>]

set -e

if [ -z "$1" ]; then
    echo "Usage: receive.sh <url> [options]" >&2
    exit 1
fi

bw receive "$@"
