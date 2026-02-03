#!/bin/bash
# Create a new login item
# Usage: create-login.sh <name> <username> <password> [uri]
# Or pipe JSON: echo '{"type":1,"name":"Test","login":{"username":"user","password":"pass"}}' | bw encode | create-login.sh

set -e

if [ -n "$1" ]; then
    NAME="$1"
    USERNAME="${2:-}"
    PASSWORD="${3:-}"
    URI="${4:-}"

    JSON=$(cat <<EOF
{
  "type": 1,
  "name": "$NAME",
  "login": {
    "username": "$USERNAME",
    "password": "$PASSWORD"
    $([ -n "$URI" ] && echo ", \"uris\": [{\"uri\": \"$URI\"}]")
  }
}
EOF
)
    echo "$JSON" | bw encode | xargs bw create item
else
    # Read encoded JSON from stdin
    read -r ENCODED
    bw create item "$ENCODED"
fi
