#!/bin/bash
# Create a new repository
# Usage: repo-create.sh <name> [--public|--private] [--description text]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: repo-create.sh <name> [--public|--private] [options]" >&2
    exit 1
fi

gh repo create "$@"
