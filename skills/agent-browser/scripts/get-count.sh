#!/bin/bash
# Count matching elements
# Usage: get-count.sh <selector>

set -e

if [ -z "$1" ]; then
    echo "Usage: get-count.sh <selector>" >&2
    exit 1
fi

agent-browser get count "$1"
