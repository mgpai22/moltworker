#!/bin/bash
# Get account origin and location info for a user
# Usage: about.sh <@handle> [--json]

set -e

if [ -z "$1" ]; then
    echo "Usage: about.sh <@handle> [--json]" >&2
    exit 1
fi

npx @steipete/bird about "$@"
