#!/bin/bash
# Download media from a message
# Usage: media-download.sh --chat <JID> --id <MSG_ID>
# Downloaded files are saved to ~/.wacli/media/

set -e

if [ -z "$1" ]; then
    echo "Usage: media-download.sh --chat <JID> --id <MSG_ID>" >&2
    echo "" >&2
    echo "Downloads media to ~/.wacli/media/" >&2
    exit 1
fi

wacli media download "$@"
