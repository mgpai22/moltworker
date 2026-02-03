#!/bin/bash
# Log out from WhatsApp
# Usage: logout.sh

set -e

echo "Logging out from WhatsApp..."
wacli auth logout
echo "Logged out. Run 'wacli auth' to authenticate again."
