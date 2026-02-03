#!/bin/bash
# Summarize audio/video file via transcription
# Usage: media.sh <media_path_or_url> [options]
# Examples:
#   media.sh "/path/to/audio.mp3"
#   media.sh "/path/to/video.mp4"
#   media.sh "https://example.com/recording.wav" --video-mode transcript

set -e

if [ -z "$1" ]; then
    echo "Usage: media.sh <media_path_or_url> [options]" >&2
    echo "" >&2
    echo "Supported formats:" >&2
    echo "  Audio: MP3, WAV, M4A, OGG, FLAC" >&2
    echo "  Video: MP4, MOV, WEBM" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --length <preset>         Output length (short/medium/long/xl/xxl)" >&2
    echo "  --video-mode transcript   Force transcription for direct URLs" >&2
    echo "  --transcriber <engine>    parakeet/canary/whisper/auto" >&2
    echo "  --lang <code>             Output language" >&2
    exit 1
fi

INPUT="$1"
shift

# For remote URLs, force transcript mode
if [[ "$INPUT" =~ ^https?:// ]]; then
    summarize "$INPUT" --video-mode transcript "$@"
else
    summarize "$INPUT" "$@"
fi
