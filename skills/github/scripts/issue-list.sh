#!/bin/bash
# List issues in a repository
# Usage: issue-list.sh [repo] [--state open|closed|all] [--limit n] [--json fields]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

gh issue list "$@"
