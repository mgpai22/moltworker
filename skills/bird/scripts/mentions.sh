#!/bin/bash
# Find tweets mentioning a user
# Usage: mentions.sh [-n count] [--user @handle] [--json]

set -e

npx @steipete/bird mentions "$@"
