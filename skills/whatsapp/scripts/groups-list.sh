#!/bin/bash
# List all groups
# Usage: groups-list.sh [options]
# Examples:
#   groups-list.sh
#   groups-list.sh --query "family"
#   groups-list.sh --json

set -e

wacli groups list "$@"
