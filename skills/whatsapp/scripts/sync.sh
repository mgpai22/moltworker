#!/bin/bash
# Sync WhatsApp messages
# Usage: sync.sh [--once|--follow]
# Options:
#   --once    Sync once and exit
#   --follow  Stay connected and sync continuously (default)

set -e

if [ "$1" = "--once" ]; then
    wacli sync --once
else
    wacli sync --follow
fi
