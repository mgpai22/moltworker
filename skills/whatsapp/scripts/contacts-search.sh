#!/bin/bash
# Search contacts
# Usage: contacts-search.sh <query>
# Example: contacts-search.sh "John"

set -e

if [ -z "$1" ]; then
    echo "Usage: contacts-search.sh <query>" >&2
    exit 1
fi

wacli contacts search "$@"
