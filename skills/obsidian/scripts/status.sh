#!/bin/bash
# Check API status and authentication
# Usage: status.sh

set -e

if [ -z "$OBSIDIAN_API_URL" ] || [ -z "$OBSIDIAN_API_KEY" ]; then
    echo "Error: OBSIDIAN_API_URL and OBSIDIAN_API_KEY must be set" >&2
    exit 1
fi

curl -s -X GET "${OBSIDIAN_API_URL}/" \
    -H "Authorization: Bearer ${OBSIDIAN_API_KEY}"
