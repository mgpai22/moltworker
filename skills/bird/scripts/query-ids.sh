#!/bin/bash
# Refresh GraphQL query IDs cache (run if you encounter errors)
# Usage: query-ids.sh [--fresh] [--json]

set -e

npx @steipete/bird query-ids "$@"
