#!/bin/bash
# Fetch your home timeline (For You or Following)
# Usage: home.sh [-n count] [--following] [--json]

set -e

npx @steipete/bird home "$@"
