#!/bin/bash
# Search messages with full-text search
# Usage: messages-search.sh <query> [options]
# Examples:
#   messages-search.sh "meeting tomorrow"
#   messages-search.sh "project" --chat 1234567890@s.whatsapp.net
#   messages-search.sh "photo" --type image

set -e

if [ -z "$1" ]; then
    echo "Usage: messages-search.sh <query> [options]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --chat <JID>     Search in specific chat" >&2
    echo "  --from <JID>     Filter by sender" >&2
    echo "  --limit <N>      Max results" >&2
    echo "  --before <TS>    Messages before timestamp" >&2
    echo "  --after <TS>     Messages after timestamp" >&2
    echo "  --type <type>    Filter by type (text|image|video|audio|document)" >&2
    echo "  --json           JSON output" >&2
    exit 1
fi

wacli messages search "$@"
