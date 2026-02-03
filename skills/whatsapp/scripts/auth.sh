#!/bin/bash
# Authenticate with WhatsApp (shows QR code to scan)
# Usage: auth.sh [options]
# After running, scan the QR code with WhatsApp on your phone:
#   WhatsApp > Settings > Linked Devices > Link a Device

set -e

echo "Starting WhatsApp authentication..."
echo "Scan the QR code with your phone's WhatsApp:"
echo "  WhatsApp > Settings > Linked Devices > Link a Device"
echo ""

wacli auth "$@"
