#!/bin/bash
# Unlock the Bitwarden vault
# Usage: unlock.sh [password]
# Returns the session key - export as BW_SESSION

set -e

if [ -n "$1" ]; then
    bw unlock "$1" --raw
else
    bw unlock --raw
fi
