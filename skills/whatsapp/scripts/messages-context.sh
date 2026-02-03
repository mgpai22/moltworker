#!/bin/bash
# Show messages around a specific message
# Usage: messages-context.sh --chat <JID> --id <MSG_ID> [--before N] [--after N]

set -e

if [ -z "$1" ]; then
    echo "Usage: messages-context.sh --chat <JID> --id <MSG_ID> [options]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --before <N>   Messages before (default: 5)" >&2
    echo "  --after <N>    Messages after (default: 5)" >&2
    exit 1
fi

wacli messages context "$@"
