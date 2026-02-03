#!/bin/bash
# List releases
# Usage: release-list.sh [repo] [--limit n]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

gh release list "$@"
