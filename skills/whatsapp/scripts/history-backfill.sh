#!/bin/bash
# Backfill older messages from a chat
# Usage: history-backfill.sh --chat <JID> [options]
# Note: Best-effort; requires your primary phone to be online
# Examples:
#   history-backfill.sh --chat 1234567890@s.whatsapp.net
#   history-backfill.sh --chat 1234567890@s.whatsapp.net --requests 10 --count 50

set -e

if [ -z "$1" ]; then
    echo "Usage: history-backfill.sh --chat <JID> [options]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --requests <N>   Number of history requests (default: 5)" >&2
    echo "  --count <N>      Messages per request (recommended: 50)" >&2
    echo "" >&2
    echo "Note: Your primary phone must be online for this to work." >&2
    exit 1
fi

wacli history backfill "$@"
