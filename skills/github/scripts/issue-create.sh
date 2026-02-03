#!/bin/bash
# Create a new issue
# Usage: issue-create.sh <title> [body] [repo] [--label label] [--assignee user]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: issue-create.sh <title> [body] [repo] [options]" >&2
    exit 1
fi

TITLE="$1"
shift

# Check if second arg is body (not a flag or repo)
if [ -n "$1" ] && [[ ! "$1" =~ ^- ]] && [[ ! "$1" =~ ^[a-zA-Z0-9_-]+/[a-zA-Z0-9_.-]+$ ]]; then
    BODY="$1"
    shift
    gh issue create --title "$TITLE" --body "$BODY" "$@"
else
    gh issue create --title "$TITLE" "$@"
fi
