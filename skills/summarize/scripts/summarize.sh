#!/bin/bash
# General summarize command - auto-detects input type
# Usage: summarize.sh <url_or_file> [options]
# Examples:
#   summarize.sh "https://example.com"
#   summarize.sh "https://youtu.be/VIDEO_ID"
#   summarize.sh "/path/to/file.pdf"
#   summarize.sh "https://example.com" --length long --model anthropic/claude-sonnet-4-5

set -e

if [ -z "$1" ]; then
    echo "Usage: summarize.sh <url_or_file> [options]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --model <provider/model>  Model to use (default: auto)" >&2
    echo "  --length <preset|chars>   Output length (short/medium/long/xl/xxl or char count)" >&2
    echo "  --lang <language>         Output language (auto, en, es, ja, etc.)" >&2
    echo "  --extract                 Extract content only, don't summarize" >&2
    echo "  --slides                  Extract video slides with timestamps" >&2
    echo "  --json                    Output JSON with diagnostics" >&2
    echo "  --verbose                 Show debug output" >&2
    exit 1
fi

summarize "$@"
