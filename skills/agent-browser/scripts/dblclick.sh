#!/bin/bash
# Double-click element
# Usage: dblclick.sh <selector>

set -e

if [ -z "$1" ]; then
    echo "Usage: dblclick.sh <selector>" >&2
    exit 1
fi

agent-browser dblclick "$1"
