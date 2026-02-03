#!/bin/bash
# View pull request check status
# Usage: pr-checks.sh <number> [repo]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: pr-checks.sh <number> [repo]" >&2
    exit 1
fi

gh pr checks "$@"
