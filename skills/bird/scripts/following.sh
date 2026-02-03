#!/bin/bash
# List users that you (or another user) follow
# Usage: following.sh [-n count] [--user <userId>] [--json]

set -e

npx @steipete/bird following "$@"
