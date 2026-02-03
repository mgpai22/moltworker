#!/bin/bash
# Rename a group
# Usage: groups-rename.sh --jid <GROUP_JID> --name <NEW_NAME>

set -e

if [ -z "$1" ]; then
    echo "Usage: groups-rename.sh --jid <GROUP_JID> --name <NEW_NAME>" >&2
    exit 1
fi

wacli groups rename "$@"
