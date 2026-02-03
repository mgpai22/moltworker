#!/bin/bash
# Check checkbox
# Usage: check.sh <selector>

set -e

if [ -z "$1" ]; then
    echo "Usage: check.sh <selector>" >&2
    exit 1
fi

agent-browser check "$1"
