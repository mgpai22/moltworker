#!/bin/bash
# Select dropdown option
# Usage: select.sh <selector> <value>

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: select.sh <selector> <value>" >&2
    exit 1
fi

agent-browser select "$1" "$2"
