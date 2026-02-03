#!/bin/bash
# Add a comment to an issue
# Usage: issue-comment.sh <number> <body> [repo]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: issue-comment.sh <number> <body> [repo]" >&2
    exit 1
fi

NUMBER="$1"
BODY="$2"
shift 2

gh issue comment "$NUMBER" --body "$BODY" "$@"
