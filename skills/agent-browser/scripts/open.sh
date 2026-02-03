#!/bin/bash
# Navigate to URL
# Usage: open.sh <url>

set -e

if [ -z "$1" ]; then
    echo "Usage: open.sh <url>" >&2
    exit 1
fi

agent-browser open "$1"
