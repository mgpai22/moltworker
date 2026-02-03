#!/bin/bash
# List users that follow you (or another user)
# Usage: followers.sh [-n count] [--user <userId>] [--json]

set -e

npx @steipete/bird followers "$@"
