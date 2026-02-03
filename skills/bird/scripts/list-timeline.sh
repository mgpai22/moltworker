#!/bin/bash
# Get tweets from a list timeline
# Usage: list-timeline.sh <list-id|url> [-n count] [--all] [--json]

set -e

if [ -z "$1" ]; then
    echo "Usage: list-timeline.sh <list-id|url> [options]" >&2
    echo "Options: -n count, --all, --max-pages n, --json" >&2
    exit 1
fi

npx @steipete/bird list-timeline "$@"
