#!/bin/bash
# Wait for element to appear
# Usage: wait.sh <selector>

set -e

if [ -z "$1" ]; then
    echo "Usage: wait.sh <selector>" >&2
    exit 1
fi

agent-browser wait "$1"
