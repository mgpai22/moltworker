#!/bin/bash
# Make raw GitHub API calls
# Usage: api.sh <endpoint> [method] [body]
# Examples:
#   api.sh /repos/owner/repo
#   api.sh /repos/owner/repo/issues POST '{"title":"New issue"}'
#   api.sh /user

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: api.sh <endpoint> [method] [body]" >&2
    echo "Examples:" >&2
    echo "  api.sh /repos/owner/repo" >&2
    echo "  api.sh /repos/owner/repo/issues POST '{\"title\":\"New\"}'" >&2
    exit 1
fi

ENDPOINT="$1"
METHOD="${2:-GET}"
BODY="$3"

if [ -n "$BODY" ]; then
    gh api -X "$METHOD" "$ENDPOINT" --input - <<< "$BODY"
else
    gh api -X "$METHOD" "$ENDPOINT"
fi
