#!/bin/bash
# Get element attribute
# Usage: get-attr.sh <selector> <attribute>

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: get-attr.sh <selector> <attribute>" >&2
    exit 1
fi

agent-browser get attr "$1" "$2"
