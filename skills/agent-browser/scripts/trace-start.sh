#!/bin/bash
# Start trace recording
# Usage: trace-start.sh [path]

set -e
agent-browser trace start "$@"
