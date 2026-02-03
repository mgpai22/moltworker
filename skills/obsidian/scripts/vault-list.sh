#!/bin/bash
# List files/folders in vault
# Usage: vault-list.sh [path]

set -e

if [ -z "$OBSIDIAN_API_URL" ] || [ -z "$OBSIDIAN_API_KEY" ]; then
    echo "Error: OBSIDIAN_API_URL and OBSIDIAN_API_KEY must be set" >&2
    exit 1
fi

PATH_ARG="${1:-}"

curl -s -X GET "${OBSIDIAN_API_URL}/vault/${PATH_ARG}" \
    -H "Authorization: Bearer ${OBSIDIAN_API_KEY}" \
    --data-urlencode ""
