#!/bin/bash
# Fetch trending topics (alias for news)
# Usage: trending.sh [-n count] [--json]

set -e

npx @steipete/bird trending "$@"
