#!/bin/bash
# Show contact details
# Usage: contacts-show.sh --jid <JID>

set -e

if [ -z "$1" ]; then
    echo "Usage: contacts-show.sh --jid <JID>" >&2
    exit 1
fi

wacli contacts show "$@"
