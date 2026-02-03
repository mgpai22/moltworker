#!/bin/bash
# Generate a passphrase
# Usage: generate-passphrase.sh [--words <n>] [--separator <char>]

set -e

# Default: 4 words with dashes
if [ $# -eq 0 ]; then
    bw generate --passphrase --words 4 --separator "-"
else
    bw generate --passphrase "$@"
fi
