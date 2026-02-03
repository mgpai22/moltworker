#!/bin/bash
# Get element text content
# Usage: get-text.sh <selector>

set -e

if [ -z "$1" ]; then
    echo "Usage: get-text.sh <selector>" >&2
    exit 1
fi

agent-browser get text "$1"
