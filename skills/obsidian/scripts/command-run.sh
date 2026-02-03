#!/bin/bash
# Execute an Obsidian command
# Usage: command-run.sh <command-id>

set -e

if [ -z "$1" ]; then
    echo "Usage: command-run.sh <command-id>" >&2
    exit 1
fi

if [ -z "$OBSIDIAN_API_URL" ] || [ -z "$OBSIDIAN_API_KEY" ]; then
    echo "Error: OBSIDIAN_API_URL and OBSIDIAN_API_KEY must be set" >&2
    exit 1
fi

COMMAND_ID="$1"

curl -s -X POST "${OBSIDIAN_API_URL}/commands/${COMMAND_ID}/" \
    -H "Authorization: Bearer ${OBSIDIAN_API_KEY}"
