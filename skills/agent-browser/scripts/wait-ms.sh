#!/bin/bash
# Wait for specified milliseconds
# Usage: wait-ms.sh <milliseconds>

set -e

if [ -z "$1" ]; then
    echo "Usage: wait-ms.sh <milliseconds>" >&2
    exit 1
fi

agent-browser wait "$1"
