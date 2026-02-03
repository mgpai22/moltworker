#!/bin/bash
# Export vault data
# Usage: export.sh [format] [--output <file>]
# Formats: json (default), csv, encrypted_json

set -e

FORMAT="${1:-json}"
shift 2>/dev/null || true

bw export --format "$FORMAT" "$@"
