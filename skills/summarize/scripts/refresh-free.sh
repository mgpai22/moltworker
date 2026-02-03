#!/bin/bash
# Refresh the free OpenRouter model preset
# Usage: refresh-free.sh [options]
# Examples:
#   refresh-free.sh
#   refresh-free.sh --set-default

set -e

if [ -z "$OPENROUTER_API_KEY" ]; then
    echo "Error: OPENROUTER_API_KEY is required for free models" >&2
    echo "" >&2
    echo "Set it with: export OPENROUTER_API_KEY=sk-or-..." >&2
    exit 1
fi

echo "Refreshing free model preset..."
echo "This will test available free models and update ~/.summarize/config.json"
echo ""

summarize refresh-free "$@"
