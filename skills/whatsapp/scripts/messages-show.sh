#!/bin/bash
# Show a specific message
# Usage: messages-show.sh --chat <JID> --id <MSG_ID>

set -e

if [ -z "$1" ]; then
    echo "Usage: messages-show.sh --chat <JID> --id <MSG_ID>" >&2
    exit 1
fi

wacli messages show "$@"
