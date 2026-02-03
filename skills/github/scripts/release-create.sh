#!/bin/bash
# Create a release
# Usage: release-create.sh <tag> [--title text] [--notes text] [repo]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: release-create.sh <tag> [--title text] [--notes text] [repo]" >&2
    exit 1
fi

gh release create "$@"
