#!/bin/bash
# Edit an existing item
# Usage: edit-item.sh <id> [encoded_json]
# If no JSON provided, fetches current item for reference

set -e

if [ -z "$1" ]; then
    echo "Usage: edit-item.sh <id> [encoded_json]" >&2
    echo "Tip: Get current item first with: bw get item <id> | bw encode" >&2
    exit 1
fi

ID="$1"

if [ -n "$2" ]; then
    bw edit item "$ID" "$2"
else
    echo "Current item (encode and modify to edit):"
    bw get item "$ID" --pretty
fi
