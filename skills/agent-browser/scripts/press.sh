#!/bin/bash
# Press keyboard key
# Usage: press.sh <key>
# Keys: Enter, Tab, Escape, Control+a, etc.

set -e

if [ -z "$1" ]; then
    echo "Usage: press.sh <key>" >&2
    exit 1
fi

agent-browser press "$1"
