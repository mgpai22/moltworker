#!/bin/bash
# Click element
# Usage: click.sh <selector>
# Selector can be ref (@e1) or CSS selector

set -e

if [ -z "$1" ]; then
    echo "Usage: click.sh <selector>" >&2
    exit 1
fi

agent-browser click "$1"
