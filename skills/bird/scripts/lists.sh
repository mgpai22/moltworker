#!/bin/bash
# List your Twitter lists
# Usage: lists.sh [--member-of] [-n count] [--json]

set -e

npx @steipete/bird lists "$@"
