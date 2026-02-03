#!/bin/bash
# Clone a repository
# Usage: repo-clone.sh <repo> [directory]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: repo-clone.sh <repo> [directory]" >&2
    exit 1
fi

gh repo clone "$@"
