#!/bin/bash
# Summarize a podcast episode
# Usage: podcast.sh <podcast_url> [options]
# Examples:
#   podcast.sh "https://feeds.example.com/podcast.xml"
#   podcast.sh "https://podcasts.apple.com/us/podcast/episode/id123?i=456"
#   podcast.sh "https://open.spotify.com/episode/EPISODE_ID"

set -e

if [ -z "$1" ]; then
    echo "Usage: podcast.sh <podcast_url> [options]" >&2
    echo "" >&2
    echo "Supported sources:" >&2
    echo "  - RSS feeds (Podcasting 2.0 transcripts when available)" >&2
    echo "  - Apple Podcasts episode URLs" >&2
    echo "  - Spotify episode URLs" >&2
    echo "  - Amazon Music / Audible podcast pages" >&2
    echo "  - Podbean, Podchaser" >&2
    echo "" >&2
    echo "Options:" >&2
    echo "  --length <preset>    Output length (short/medium/long/xl/xxl)" >&2
    echo "  --extract            Get transcript only, don't summarize" >&2
    echo "  --lang <code>        Output language" >&2
    exit 1
fi

URL="$1"
shift

summarize "$URL" "$@"
