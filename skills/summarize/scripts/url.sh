#!/bin/bash
# Summarize a web page URL
# Usage: url.sh <url> [options]
# Examples:
#   url.sh "https://example.com/article"
#   url.sh "https://example.com" --length long
#   url.sh "https://example.com" --model openai/gpt-5-mini

set -e

if [ -z "$1" ]; then
    echo "Usage: url.sh <url> [options]" >&2
    exit 1
fi

URL="$1"
shift

# Validate URL format
if [[ ! "$URL" =~ ^https?:// ]]; then
    echo "Error: Invalid URL format. Must start with http:// or https://" >&2
    exit 1
fi

summarize "$URL" "$@"
