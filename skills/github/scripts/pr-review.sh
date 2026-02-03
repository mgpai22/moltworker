#!/bin/bash
# Review a pull request
# Usage: pr-review.sh <number> <approve|comment|request-changes> [body] [repo]

set -e

if [ -z "$GH_TOKEN" ]; then
    echo "Error: GH_TOKEN environment variable not set" >&2
    exit 1
fi

if [ -z "$1" ] || [ -z "$2" ]; then
    echo "Usage: pr-review.sh <number> <approve|comment|request-changes> [body] [repo]" >&2
    exit 1
fi

NUMBER="$1"
ACTION="$2"
shift 2

case "$ACTION" in
    approve)
        gh pr review "$NUMBER" --approve "$@"
        ;;
    comment)
        if [ -n "$1" ] && [[ ! "$1" =~ ^- ]]; then
            BODY="$1"
            shift
            gh pr review "$NUMBER" --comment --body "$BODY" "$@"
        else
            gh pr review "$NUMBER" --comment "$@"
        fi
        ;;
    request-changes)
        if [ -n "$1" ] && [[ ! "$1" =~ ^- ]]; then
            BODY="$1"
            shift
            gh pr review "$NUMBER" --request-changes --body "$BODY" "$@"
        else
            gh pr review "$NUMBER" --request-changes "$@"
        fi
        ;;
    *)
        echo "Error: action must be approve, comment, or request-changes" >&2
        exit 1
        ;;
esac
