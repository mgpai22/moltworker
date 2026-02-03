#!/bin/bash
# View pull request details
# Usage: pr-view.sh <number> [repo] [--json fields]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: pr-view.sh <number> [repo] [options]" >&2
    exit 1
fi

gh pr view "$@"
