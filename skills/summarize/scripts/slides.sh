#!/bin/bash
# Extract slides from YouTube video with timestamps
# Usage: slides.sh <youtube_url> [options]
# Examples:
#   slides.sh "https://youtu.be/VIDEO_ID"
#   slides.sh "https://youtu.be/VIDEO_ID" --slides-ocr
#   slides.sh "https://youtu.be/VIDEO_ID" --slides-max 10

set -e

if [ -z "$1" ]; then
    echo "Usage: slides.sh <youtube_url> [options]" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --slides-ocr              Run OCR on extracted slides" >&2
    echo "  --slides-dir <dir>        Output directory (default: ./slides)" >&2
    echo "  --slides-max <count>      Max slides to extract (default: 6)" >&2
    echo "  --slides-min-duration <s> Min seconds between slides" >&2
    echo "  --extract                 Extract only, don't summarize" >&2
    exit 1
fi

URL="$1"
shift

# Validate YouTube URL
if [[ ! "$URL" =~ (youtube\.com|youtu\.be) ]]; then
    echo "Error: Not a YouTube URL" >&2
    exit 1
fi

summarize "$URL" --youtube auto --slides "$@"
