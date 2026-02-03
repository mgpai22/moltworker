#!/bin/bash
# Create a pull request
# Usage: pr-create.sh <title> [body] [--base branch] [--head branch] [repo]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: pr-create.sh <title> [body] [options]" >&2
    exit 1
fi

TITLE="$1"
shift

# Check if second arg is body (not a flag or repo)
if [ -n "$1" ] && [[ ! "$1" =~ ^- ]] && [[ ! "$1" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$ ]]; then
    BODY="$1"
    shift
    gh pr create --title "$TITLE" --body "$BODY" "$@"
else
    gh pr create --title "$TITLE" "$@"
fi
