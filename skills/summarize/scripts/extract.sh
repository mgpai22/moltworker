#!/bin/bash
# Extract content from URL without summarizing
# Usage: extract.sh <url> [options]
# Examples:
#   extract.sh "https://example.com"
#   extract.sh "https://example.com" --format md
#   extract.sh "https://youtu.be/VIDEO_ID"

set -e

if [ -z "$1" ]; then
    echo "Usage: extract.sh <url> [options]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --format <md|text>       Output format (default: md for URLs)" >&2
    echo "  --markdown-mode <mode>   off/auto/llm/readability" >&2
    echo "  --firecrawl <mode>       off/auto/always" >&2
    exit 1
fi

URL="$1"
shift

summarize "$URL" --extract "$@"
