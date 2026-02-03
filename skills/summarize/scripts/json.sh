#!/bin/bash
# Get detailed JSON output with diagnostics and metrics
# Usage: json.sh <url_or_file> [options]
# Examples:
#   json.sh "https://example.com"
#   json.sh "https://youtu.be/VIDEO_ID"

set -e

if [ -z "$1" ]; then
    echo "Usage: json.sh <url_or_file> [options]" >&2
    echo "" >&2
    echo "Returns JSON with:" >&2
    echo "  - summary: The generated summary" >&2
    echo "  - metrics: Token counts, timing, cost estimates" >&2
    echo "  - diagnostics: Model used, cache status, extraction info" >&2
    exit 1
fi

INPUT="$1"
shift

summarize "$INPUT" --json "$@"
