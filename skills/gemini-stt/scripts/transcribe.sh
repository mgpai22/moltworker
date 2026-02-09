#!/bin/bash
# Transcribe an audio file using the Gemini API
# Usage: transcribe.sh <audio-file> [--model <model>] [--prompt "..."] [--json]

set -e

usage() {
    echo "Usage: transcribe.sh <audio-file> [--model <model>] [--prompt \"...\"] [--json]" >&2
    exit 1
}

if [ -z "${1:-}" ] || [ "${1:-}" = "-h" ] || [ "${1:-}" = "--help" ]; then
    usage
fi

FILE="$1"
shift

MODEL="gemini-2.5-flash"
PROMPT="Transcribe the audio. Return plain text."
OUTPUT_JSON=false

while [ $# -gt 0 ]; do
    case "$1" in
        --model)
            MODEL="$2"
            shift 2
            ;;
        --prompt)
            PROMPT="$2"
            shift 2
            ;;
        --json)
            OUTPUT_JSON=true
            shift
            ;;
        *)
            echo "Unknown argument: $1" >&2
            usage
            ;;
    esac
done

if [ ! -f "$FILE" ]; then
    echo "Error: file not found: $FILE" >&2
    exit 1
fi

if [ -z "${GEMINI_API_KEY:-}" ]; then
    echo "Error: GEMINI_API_KEY environment variable not set" >&2
    exit 1
fi

EXT="${FILE##*.}"
MIME="application/octet-stream"
case "${EXT,,}" in
    wav) MIME="audio/wav" ;;
    mp3) MIME="audio/mpeg" ;;
    m4a) MIME="audio/mp4" ;;
    mp4) MIME="audio/mp4" ;;
    webm) MIME="audio/webm" ;;
    ogg) MIME="audio/ogg" ;;
    flac) MIME="audio/flac" ;;
    aac) MIME="audio/aac" ;;
esac

AUDIO_B64=$(base64 "$FILE" | tr -d '\n')

DATA=$(jq -n \
    --arg prompt "$PROMPT" \
    --arg mime "$MIME" \
    --arg data "$AUDIO_B64" \
    '{contents:[{role:"user", parts:[{text:$prompt},{inlineData:{mimeType:$mime,data:$data}}]}]}')

URL="https://generativelanguage.googleapis.com/v1beta/models/${MODEL}:generateContent?key=${GEMINI_API_KEY}"
RESPONSE=$(curl -s -X POST "$URL" -H "Content-Type: application/json" -d "$DATA")

if echo "$RESPONSE" | jq -e '.error' >/dev/null 2>&1; then
    echo "$RESPONSE" | jq '.' >&2
    exit 1
fi

if [ "$OUTPUT_JSON" = true ]; then
    echo "$RESPONSE" | jq '.'
    exit 0
fi

TEXT=$(echo "$RESPONSE" | jq -r '.candidates[0].content.parts[0].text // empty')
if [ -z "$TEXT" ]; then
    echo "$RESPONSE" | jq '.' >&2
    exit 1
fi

echo "$TEXT"
