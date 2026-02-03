#!/bin/bash
# Get snapshot as JSON
# Usage: snapshot-json.sh

set -e
agent-browser snapshot -i --json
