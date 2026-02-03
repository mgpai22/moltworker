#!/bin/bash
# Get element innerHTML
# Usage: get-html.sh <selector>

set -e

if [ -z "$1" ]; then
    echo "Usage: get-html.sh <selector>" >&2
    exit 1
fi

agent-browser get html "$1"
