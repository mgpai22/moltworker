#!/bin/bash
# Restore an item from trash
# Usage: restore-item.sh <id>

set -e

if [ -z "$1" ]; then
    echo "Usage: restore-item.sh <id>" >&2
    exit 1
fi

bw restore item "$1"
