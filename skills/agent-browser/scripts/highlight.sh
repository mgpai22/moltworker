#!/bin/bash
# Highlight element on page
# Usage: highlight.sh <selector>

set -e

if [ -z "$1" ]; then
    echo "Usage: highlight.sh <selector>" >&2
    exit 1
fi

agent-browser highlight "$1"
