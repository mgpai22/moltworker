#!/bin/bash
# Scroll page
# Usage: scroll.sh <direction> [pixels]
# Direction: up, down, left, right

set -e

if [ -z "$1" ]; then
    echo "Usage: scroll.sh <direction> [pixels]" >&2
    exit 1
fi

agent-browser scroll "$@"
