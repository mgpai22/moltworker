#!/bin/bash
# List workflow runs
# Usage: run-list.sh [repo] [--limit n] [--workflow name] [--json fields]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

gh run list "$@"
