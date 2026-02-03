#!/bin/bash
# Trigger a workflow
# Usage: workflow-run.sh <workflow> [repo] [--ref branch] [-f key=value]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: workflow-run.sh <workflow> [repo] [options]" >&2
    exit 1
fi

gh workflow run "$@"
