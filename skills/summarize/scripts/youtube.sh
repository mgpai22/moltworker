#!/bin/bash
# Summarize a YouTube video
# Usage: youtube.sh <youtube_url> [options]
# Examples:
#   youtube.sh "https://youtu.be/dQw4w9WgXcQ"
#   youtube.sh "https://www.youtube.com/watch?v=VIDEO_ID" --length long
#   youtube.sh "https://youtu.be/VIDEO_ID" --slides --slides-ocr

set -e

if [ -z "$1" ]; then
    echo "Usage: youtube.sh <youtube_url> [options]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --length <preset>    Output length (short/medium/long/xl/xxl)" >&2
    echo "  --slides             Extract video slides/screenshots" >&2
    echo "  --slides-ocr         Run OCR on extracted slides" >&2
    echo "  --extract            Get transcript only, don't summarize" >&2
    echo "  --lang <code>        Output language" >&2
    exit 1
fi

URL="$1"
shift

# Validate YouTube URL
if [[ ! "$URL" =~ (youtube\.com|youtu\.be) ]]; then
    echo "Error: Not a YouTube URL. Use 'summarize.sh' for other URLs." >&2
    exit 1
fi

summarize "$URL" --youtube auto "$@"
