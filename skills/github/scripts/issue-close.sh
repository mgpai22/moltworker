#!/bin/bash
# Close an issue
# Usage: issue-close.sh <number> [repo] [--comment text]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: issue-close.sh <number> [repo] [options]" >&2
    exit 1
fi

gh issue close "$@"
