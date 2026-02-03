#!/bin/bash
# Generate a secure password
# Usage: generate.sh [options]
# Options:
#   -l, --lowercase   Include lowercase chars
#   -u, --uppercase   Include uppercase chars
#   -n, --number      Include numbers
#   -s, --special     Include special chars
#   --length <n>      Password length (default: 18)
#   --passphrase      Generate a passphrase instead

set -e

# Default: all character types, 18 chars
if [ $# -eq 0 ]; then
    bw generate -lusn --length 18
else
    bw generate "$@"
fi
