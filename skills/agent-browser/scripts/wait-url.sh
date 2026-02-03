#!/bin/bash
# Wait for URL to match pattern
# Usage: wait-url.sh <pattern>
# Example: wait-url.sh "**/dashboard"

set -e

if [ -z "$1" ]; then
    echo "Usage: wait-url.sh <pattern>" >&2
    exit 1
fi

agent-browser wait --url "$1"
