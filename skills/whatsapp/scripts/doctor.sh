#!/bin/bash
# Run WhatsApp CLI diagnostics
# Usage: doctor.sh [--connect]

set -e
wacli doctor "$@"
