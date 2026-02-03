#!/bin/bash
# Take screenshot
# Usage: screenshot.sh [path]

set -e
agent-browser screenshot "$@"
