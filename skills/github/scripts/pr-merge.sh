#!/bin/bash
# Merge a pull request
# Usage: pr-merge.sh <number> [repo] [--squash|--rebase|--merge] [--delete-branch]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: pr-merge.sh <number> [repo] [options]" >&2
    exit 1
fi

gh pr merge "$@"
