#!/bin/bash
# List vault items with optional search
# Usage: list-items.sh [search_term]

set -e

if [ -n "$1" ]; then
    bw list items --search "$1" --pretty
else
    bw list items --pretty
fi
