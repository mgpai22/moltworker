#!/bin/bash
# View repository details
# Usage: repo-view.sh [repo] [--json fields]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

gh repo view "$@"
