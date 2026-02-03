#!/bin/bash
# Re-run a workflow
# Usage: run-rerun.sh <run-id> [repo] [--failed]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: run-rerun.sh <run-id> [repo] [options]" >&2
    exit 1
fi

gh run rerun "$@"
