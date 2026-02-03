#!/bin/bash
# Execute JavaScript in browser
# Usage: eval.sh <javascript>

set -e

if [ -z "$1" ]; then
    echo "Usage: eval.sh <javascript>" >&2
    exit 1
fi

agent-browser eval "$1"
