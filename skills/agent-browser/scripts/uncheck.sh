#!/bin/bash
# Uncheck checkbox
# Usage: uncheck.sh <selector>

set -e

if [ -z "$1" ]; then
    echo "Usage: uncheck.sh <selector>" >&2
    exit 1
fi

agent-browser uncheck "$1"
