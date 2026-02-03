#!/bin/bash
# Create a gist
# Usage: gist-create.sh <file> [--public] [--desc description]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: gist-create.sh <file> [--public] [--desc description]" >&2
    exit 1
fi

gh gist create "$@"
