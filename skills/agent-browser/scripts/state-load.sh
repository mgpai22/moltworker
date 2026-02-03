#!/bin/bash
# Load browser auth/session state
# Usage: state-load.sh <path>

set -e

if [ -z "$1" ]; then
    echo "Usage: state-load.sh <path>" >&2
    exit 1
fi

agent-browser state load "$1"
