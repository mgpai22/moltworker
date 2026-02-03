#!/bin/bash
# List pull requests
# Usage: pr-list.sh [repo] [--state open|closed|merged|all] [--limit n] [--json fields]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

gh pr list "$@"
