#!/bin/bash
# List your liked tweets
# Usage: likes.sh [-n count] [--all] [--json]

set -e

npx @steipete/bird likes "$@"
