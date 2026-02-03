#!/bin/bash
# View a gist
# Usage: gist-view.sh <id|url>

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ]; then
    echo "Usage: gist-view.sh <id|url>" >&2
    exit 1
fi

gh gist view "$@"
