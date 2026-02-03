#!/bin/bash
# View release details
# Usage: release-view.sh <tag> [repo]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: release-view.sh <tag> [repo]" >&2
    exit 1
fi

gh release view "$@"
