#!/bin/bash
# List all chats
# Usage: chats-list.sh [options]
# Examples:
#   chats-list.sh
#   chats-list.sh --query "work"
#   chats-list.sh --json --limit 100

set -e

wacli chats list "$@"
