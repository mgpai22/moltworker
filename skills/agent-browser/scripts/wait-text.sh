#!/bin/bash
# Wait for text to appear on page
# Usage: wait-text.sh <text>

set -e

if [ -z "$1" ]; then
    echo "Usage: wait-text.sh <text>" >&2
    exit 1
fi

agent-browser wait --text "$1"
