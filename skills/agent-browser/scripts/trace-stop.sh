#!/bin/bash
# Stop trace and save to file
# Usage: trace-stop.sh [path]

set -e
agent-browser trace stop "$@"
