#!/bin/bash
# List your gists
# Usage: gist-list.sh [--limit n] [--public|--secret]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

gh gist list "$@"
