#!/bin/bash
# Send a text message
# Usage: send-text.sh --to <PHONE_OR_JID> --message <TEXT>
# Examples:
#   send-text.sh --to 1234567890 --message "Hello!"
#   send-text.sh --to 123456789@g.us --message "Hello group!"

set -e

if [ -z "$1" ]; then
    echo "Usage: send-text.sh --to <PHONE_OR_JID> --message <TEXT>" >&2
    echo "" >&2
    echo "Examples:" >&2
    echo "  send-text.sh --to 1234567890 --message \"Hello!\"" >&2
    echo "  send-text.sh --to 123456789@g.us --message \"Hello group!\"" >&2
    exit 1
fi

wacli send text "$@"
