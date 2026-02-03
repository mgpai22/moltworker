#!/bin/bash
# Search pull requests
# Usage: search-prs.sh <query> [--limit n] [--json fields]
# Example: search-prs.sh "is:open author:username"

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: search-prs.sh <query> [options]" >&2
    echo "Example: search-prs.sh \"is:open author:username\"" >&2
    exit 1
fi

gh search prs "$@"
