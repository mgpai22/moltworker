#!/bin/bash
# Search repositories
# Usage: search-repos.sh <query> [--limit n] [--json fields]
# Example: search-repos.sh "language:rust stars:>1000"

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: search-repos.sh <query> [options]" >&2
    echo "Example: search-repos.sh \"language:rust stars:>1000\"" >&2
    exit 1
fi

gh search repos "$@"
