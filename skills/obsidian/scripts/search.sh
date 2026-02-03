#!/bin/bash
# Search notes by content
# Usage: search.sh <query>

set -e

if [ -z "$1" ]; then
    echo "Usage: search.sh <query>" >&2
    exit 1
fi

if [ -z "$OBSIDIAN_API_URL" ] || [ -z "$OBSIDIAN_API_KEY" ]; then
    echo "Error: OBSIDIAN_API_URL and OBSIDIAN_API_KEY must be set" >&2
    exit 1
fi

QUERY="$1"

curl -s -X POST "${OBSIDIAN_API_URL}/search/simple/" \
    -H "Authorization: Bearer ${OBSIDIAN_API_KEY}" \
    -H "Content-Type: application/json" \
    -d "{\"query\": \"$QUERY\"}"
