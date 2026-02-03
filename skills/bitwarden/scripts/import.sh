#!/bin/bash
# Import vault data from file
# Usage: import.sh <format> <file>
# Formats: See 'bw import --formats' for full list

set -e

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: import.sh <format> <file>" >&2
    echo "Run 'bw import --formats' for supported formats" >&2
    exit 1
fi

bw import "$1" "$2"
