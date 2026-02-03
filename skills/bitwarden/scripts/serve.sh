#!/bin/bash
# Start Bitwarden REST API server
# Usage: serve.sh [--port <port>] [--hostname <host>]

set -e

bw serve "$@"
