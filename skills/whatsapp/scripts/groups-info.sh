#!/bin/bash
# Show group information
# Usage: groups-info.sh --jid <GROUP_JID>

set -e

if [ -z "$1" ]; then
    echo "Usage: groups-info.sh --jid <GROUP_JID>" >&2
    exit 1
fi

wacli groups info "$@"
