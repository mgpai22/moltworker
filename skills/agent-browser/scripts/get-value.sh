#!/bin/bash
# Get input value
# Usage: get-value.sh <selector>

set -e

if [ -z "$1" ]; then
    echo "Usage: get-value.sh <selector>" >&2
    exit 1
fi

agent-browser get value "$1"
