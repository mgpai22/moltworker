#!/bin/bash
# Read a tweet by URL or ID
# Usage: read.sh <tweet-url|id> [--json]

set -e

if [ -z "$1" ]; then
    echo "Usage: read.sh <tweet-url|id> [options]" >&2
    echo "Options: --json, --json-full, --plain" >&2
    exit 1
fi

npx @steipete/bird read "$@"
