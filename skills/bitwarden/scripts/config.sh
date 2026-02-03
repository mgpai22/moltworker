#!/bin/bash
# Configure Bitwarden CLI settings
# Usage: config.sh <setting> [value]
# Settings: server, device

set -e

if [ -z "$1" ]; then
    echo "Usage: config.sh <setting> [value]" >&2
    echo "Settings:" >&2
    echo "  server <url>  - Set server URL (for self-hosted)" >&2
    echo "  device <id>   - Set device ID" >&2
    exit 1
fi

bw config "$@"
