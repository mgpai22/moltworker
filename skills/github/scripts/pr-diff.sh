#!/bin/bash
# View pull request diff
# Usage: pr-diff.sh <number> [repo]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: pr-diff.sh <number> [repo]" >&2
    exit 1
fi

gh pr diff "$@"
