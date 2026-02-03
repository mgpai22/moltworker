#!/bin/bash
# Create a secure note
# Usage: create-note.sh <name> [note_content]

set -e

if [ -z "$1" ]; then
    echo "Usage: create-note.sh <name> [note_content]" >&2
    exit 1
fi

NAME="$1"
NOTES="${2:-}"

JSON=$(cat <<EOF
{
  "type": 2,
  "name": "$NAME",
  "secureNote": {
    "type": 0
  },
  "notes": "$NOTES"
}
EOF
)

echo "$JSON" | bw encode | xargs bw create item
