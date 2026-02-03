#!/bin/bash
# List your bookmarked tweets
# Usage: bookmarks.sh [-n count] [--folder-id id] [--all] [--json]

set -e

npx @steipete/bird bookmarks "$@"
