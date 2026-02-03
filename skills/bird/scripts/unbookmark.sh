#!/bin/bash
# Remove a bookmark by tweet ID or URL
# Usage: unbookmark.sh <tweet-url|id>

set -e

if [ -z "$1" ]; then
    echo "Usage: unbookmark.sh <tweet-url|id>" >&2
    exit 1
fi

npx @steipete/bird unbookmark "$@"
