#!/bin/bash
# Save browser auth/session state
# Usage: state-save.sh <path>

set -e

if [ -z "$1" ]; then
    echo "Usage: state-save.sh <path>" >&2
    exit 1
fi

agent-browser state save "$1"
