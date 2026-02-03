#!/bin/bash
# Open note in Obsidian app
# Usage: open.sh <path>

set -e

if [ -z "$1" ]; then
    echo "Usage: open.sh <path>" >&2
    exit 1
fi

if [ -z "$OBSIDIAN_API_URL" ] || [ -z "$OBSIDIAN_API_KEY" ]; then
    echo "Error: OBSIDIAN_API_URL and OBSIDIAN_API_KEY must be set" >&2
    exit 1
fi

NOTE_PATH="$1"

curl -s -X POST "${OBSIDIAN_API_URL}/open/${NOTE_PATH}" \
    -H "Authorization: Bearer ${OBSIDIAN_API_KEY}"
