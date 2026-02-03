#!/bin/bash
# Login to Bitwarden
# Usage: login.sh [email] [password]
# Or set BW_EMAIL and BW_PASSWORD env vars for automatic login
# For API key login: Set BW_CLIENTID and BW_CLIENTSECRET, then run with --apikey

set -e

# Check if already logged in
STATUS=$(bw status 2>/dev/null | grep -o '"status":"[^"]*"' | cut -d'"' -f4 || echo "unauthenticated")
if [ "$STATUS" != "unauthenticated" ]; then
    echo "Already logged in (status: $STATUS)"
    exit 0
fi

if [ "$1" = "--apikey" ]; then
    bw login --apikey --nointeraction
elif [ -n "$1" ] && [ -n "$2" ]; then
    # Email and password provided as args
    bw login "$1" "$2" --nointeraction
elif [ -n "$BW_EMAIL" ] && [ -n "$BW_PASSWORD" ]; then
    # Use env vars
    bw login "$BW_EMAIL" "$BW_PASSWORD" --nointeraction
elif [ -n "$1" ]; then
    # Only email provided
    bw login "$1" --nointeraction
else
    echo "Usage: login.sh [email] [password]"
    echo "Or set BW_EMAIL and BW_PASSWORD environment variables"
    exit 1
fi
