#!/bin/bash
# Execute GraphQL queries
# Usage: graphql.sh <query>
# Example: graphql.sh 'query { viewer { login } }'

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: graphql.sh <query>" >&2
    echo "Example: graphql.sh 'query { viewer { login } }'" >&2
    exit 1
fi

gh api graphql -f query="$1"
