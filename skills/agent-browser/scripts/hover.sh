#!/bin/bash
# Hover over element
# Usage: hover.sh <selector>

set -e

if [ -z "$1" ]; then
    echo "Usage: hover.sh <selector>" >&2
    exit 1
fi

agent-browser hover "$1"
