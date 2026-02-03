#!/bin/bash
# List replies to a tweet
# Usage: replies.sh <tweet-url|id> [--max-pages n] [--json]

set -e

if [ -z "$1" ]; then
    echo "Usage: replies.sh <tweet-url|id> [options]" >&2
    echo "Options: --max-pages n, --all, --json, --delay ms" >&2
    exit 1
fi

npx @steipete/bird replies "$@"
