#!/bin/bash
# Search code
# Usage: search-code.sh <query> [--limit n] [--json fields]
# Example: search-code.sh "filename:package.json express"

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: search-code.sh <query> [options]" >&2
    echo "Example: search-code.sh \"filename:package.json express\"" >&2
    exit 1
fi

gh search code "$@"
