#!/bin/bash
# Show chat details
# Usage: chats-show.sh --jid <JID>

set -e

if [ -z "$1" ]; then
    echo "Usage: chats-show.sh --jid <JID>" >&2
    exit 1
fi

wacli chats show "$@"
