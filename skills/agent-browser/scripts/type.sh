#!/bin/bash
# Type text into element (without clearing)
# Usage: type.sh <selector> <text>

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: type.sh <selector> <text>" >&2
    exit 1
fi

agent-browser type "$1" "$2"
