#!/bin/bash
# Read note contents (markdown)
# Usage: note-read.sh <path>

set -e

if [ -z "$1" ]; then
    echo "Usage: note-read.sh <path>" >&2
    exit 1
fi

if [ -z "$OBSIDIAN_API_URL" ] || [ -z "$OBSIDIAN_API_KEY" ]; then
    echo "Error: OBSIDIAN_API_URL and OBSIDIAN_API_KEY must be set" >&2
    exit 1
fi

NOTE_PATH="$1"

curl -s -X GET "${OBSIDIAN_API_URL}/vault/${NOTE_PATH}" \
    -H "Authorization: Bearer ${OBSIDIAN_API_KEY}" \
    -H "Accept: text/markdown"
