#!/bin/bash
# Get tweets from a user's profile timeline
# Usage: user-tweets.sh <@handle> [-n count] [--json]

set -e

if [ -z "$1" ]; then
    echo "Usage: user-tweets.sh <@handle> [options]" >&2
    echo "Options: -n count, --max-pages n, --json" >&2
    exit 1
fi

npx @steipete/bird user-tweets "$@"
