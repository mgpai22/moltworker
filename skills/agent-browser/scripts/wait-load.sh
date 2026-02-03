#!/bin/bash
# Wait for network idle (page fully loaded)
# Usage: wait-load.sh

set -e
agent-browser wait --load networkidle
