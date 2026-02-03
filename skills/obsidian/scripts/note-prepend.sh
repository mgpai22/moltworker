#!/bin/bash
# Prepend content to a note
# Usage: note-prepend.sh <path> <content>

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: note-prepend.sh <path> <content>" >&2
    exit 1
fi

if [ -z "$OBSIDIAN_API_URL" ] || [ -z "$OBSIDIAN_API_KEY" ]; then
    echo "Error: OBSIDIAN_API_URL and OBSIDIAN_API_KEY must be set" >&2
    exit 1
fi

NOTE_PATH="$1"
CONTENT="$2"

curl -s -X PATCH "${OBSIDIAN_API_URL}/vault/${NOTE_PATH}" \
    -H "Authorization: Bearer ${OBSIDIAN_API_KEY}" \
    -H "Content-Type: text/markdown" \
    -d "$CONTENT"
