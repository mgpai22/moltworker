#!/bin/bash
# Checkout a pull request locally
# Usage: pr-checkout.sh <number> [repo]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: pr-checkout.sh <number> [repo]" >&2
    exit 1
fi

gh pr checkout "$@"
