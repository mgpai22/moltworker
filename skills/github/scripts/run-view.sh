#!/bin/bash
# View workflow run details
# Usage: run-view.sh <run-id> [repo] [--log]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: run-view.sh <run-id> [repo] [options]" >&2
    exit 1
fi

gh run view "$@"
