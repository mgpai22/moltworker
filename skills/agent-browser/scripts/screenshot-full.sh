#!/bin/bash
# Take full page screenshot
# Usage: screenshot-full.sh [path]

set -e
agent-browser screenshot --full "$@"
