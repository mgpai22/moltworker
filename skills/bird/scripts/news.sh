#!/bin/bash
# Fetch AI-curated news and trending topics from X's Explore tabs
# Usage: news.sh [-n count] [--ai-only] [--sports] [--entertainment] [--json]

set -e

npx @steipete/bird news "$@"
