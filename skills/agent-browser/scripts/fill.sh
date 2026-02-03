#!/bin/bash
# Clear and fill input field
# Usage: fill.sh <selector> <text>

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: fill.sh <selector> <text>" >&2
    exit 1
fi

agent-browser fill "$1" "$2"
