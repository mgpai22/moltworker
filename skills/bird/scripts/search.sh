#!/bin/bash
# Search for tweets
# Usage: search.sh "<query>" [-n count] [--json]

set -e

if [ -z "$1" ]; then
    echo "Usage: search.sh \"<query>\" [options]" >&2
    echo "Options: -n count, --all, --max-pages n, --json" >&2
    echo "Example: search.sh \"from:steipete\" -n 10" >&2
    exit 1
fi

npx @steipete/bird search "$@"
