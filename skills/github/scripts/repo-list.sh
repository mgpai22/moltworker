#!/bin/bash
# List repositories
# Usage: repo-list.sh [owner] [--limit n] [--json fields]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

gh repo list "$@"
