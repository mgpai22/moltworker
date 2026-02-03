#!/bin/bash
# Search issues
# Usage: search-issues.sh <query> [--limit n] [--json fields]
# Example: search-issues.sh "is:open label:bug repo:owner/repo"

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: search-issues.sh <query> [options]" >&2
    echo "Example: search-issues.sh \"is:open label:bug repo:owner/repo\"" >&2
    exit 1
fi

gh search issues "$@"
