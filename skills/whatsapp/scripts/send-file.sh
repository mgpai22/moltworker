#!/bin/bash
# Send a file (image, document, etc.)
# Usage: send-file.sh --to <PHONE_OR_JID> --file <PATH> [options]
# Examples:
#   send-file.sh --to 1234567890 --file ./photo.jpg
#   send-file.sh --to 1234567890 --file ./doc.pdf --caption "Report"
#   send-file.sh --to 1234567890 --file /tmp/data --filename report.pdf

set -e

if [ -z "$1" ]; then
    echo "Usage: send-file.sh --to <PHONE_OR_JID> --file <PATH> [options]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --caption <TEXT>     Caption for the file" >&2
    echo "  --filename <NAME>    Override display filename" >&2
    echo "  --mime <TYPE>        Override MIME type" >&2
    exit 1
fi

wacli send file "$@"
