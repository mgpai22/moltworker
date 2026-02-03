#!/bin/bash
# Create a new folder
# Usage: create-folder.sh <name>

set -e

if [ -z "$1" ]; then
    echo "Usage: create-folder.sh <name>" >&2
    exit 1
fi

echo "{\"name\":\"$1\"}" | bw encode | xargs bw create folder
