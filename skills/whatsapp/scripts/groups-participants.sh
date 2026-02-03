#!/bin/bash
# Manage group participants
# Usage: groups-participants.sh <action> --jid <GROUP_JID> --user <PHONE_OR_JID>
# Actions: add, remove, promote, demote
# Examples:
#   groups-participants.sh add --jid 123456789@g.us --user 1234567890
#   groups-participants.sh remove --jid 123456789@g.us --user 1234567890
#   groups-participants.sh promote --jid 123456789@g.us --user 1234567890
#   groups-participants.sh demote --jid 123456789@g.us --user 1234567890

set -e

if [ -z "$1" ]; then
    echo "Usage: groups-participants.sh <action> --jid <GROUP_JID> --user <PHONE_OR_JID>" >&2
    echo "" >&2
    echo "Actions:" >&2
    echo "  add      Add user to group" >&2
    echo "  remove   Remove user from group" >&2
    echo "  promote  Make user an admin" >&2
    echo "  demote   Remove admin status" >&2
    exit 1
fi

ACTION="$1"
shift

wacli groups participants "$ACTION" "$@"
