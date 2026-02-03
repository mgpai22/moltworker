#!/bin/bash
# List messages from a chat
# Usage: messages-list.sh --chat <JID> [options]
# Examples:
#   messages-list.sh --chat 1234567890@s.whatsapp.net
#   messages-list.sh --chat 1234567890@s.whatsapp.net --limit 50
#   messages-list.sh --chat 123456789@g.us --after 2024-01-01

set -e

if [ -z "$1" ]; then
    echo "Usage: messages-list.sh --chat <JID> [options]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --chat <JID>     Chat JID (required)" >&2
    echo "  --limit <N>      Max messages to return" >&2
    echo "  --before <TS>    Messages before timestamp" >&2
    echo "  --after <TS>     Messages after timestamp" >&2
    echo "  --json           JSON output" >&2
    exit 1
fi

wacli messages list "$@"
