#!/bin/bash
# View or update summarize configuration
# Usage: config.sh [action]
# Examples:
#   config.sh                    # View current config
#   config.sh --show             # View current config
#   config.sh --help             # Show help

set -e

CONFIG_FILE="$HOME/.summarize/config.json"

if [ "$1" = "--help" ] || [ "$1" = "-h" ]; then
    echo "Summarize Configuration" >&2
    echo "" >&2
    echo "Config file: $CONFIG_FILE" >&2
    echo "" >&2
    echo "Example config:" >&2
    cat << 'EOF' >&2
{
  "model": "anthropic/claude-sonnet-4-5",
  "ui": { "theme": "aurora" },
  "cache": {
    "media": { "enabled": true, "ttlDays": 7, "maxMb": 2048 }
  }
}
EOF
    exit 0
fi

if [ -f "$CONFIG_FILE" ]; then
    echo "Current configuration ($CONFIG_FILE):"
    cat "$CONFIG_FILE"
else
    echo "No configuration file found at $CONFIG_FILE"
    echo ""
    echo "Create one with:"
    echo "  mkdir -p ~/.summarize"
    echo '  echo '\''{"model": "auto"}'\'' > ~/.summarize/config.json'
fi
