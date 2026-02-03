#!/bin/bash
# Get notes for an item
# Usage: get-notes.sh <name>

set -e

if [ -z "$1" ]; then
    echo "Usage: get-notes.sh <name>" >&2
    exit 1
fi

bw get notes "$1" --raw
