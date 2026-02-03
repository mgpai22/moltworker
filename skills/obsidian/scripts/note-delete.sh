#!/bin/bash
# Delete a note
# Usage: note-delete.sh <path>

set -e

if [ -z "$1" ]; then
    echo "Usage: note-delete.sh <path>" >&2
    exit 1
fi

if [ -z "$OBSIDIAN_API_URL" ] || [ -z "$OBSIDIAN_API_KEY" ]; then
    echo "Error: OBSIDIAN_API_URL and OBSIDIAN_API_KEY must be set" >&2
    exit 1
fi

NOTE_PATH="$1"

curl -s -X DELETE "${OBSIDIAN_API_URL}/vault/${NOTE_PATH}" \
    -H "Authorization: Bearer ${OBSIDIAN_API_KEY}"
