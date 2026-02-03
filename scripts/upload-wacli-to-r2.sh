#!/bin/bash
# Upload local wacli session directly to R2
# This bypasses the API size limits for large session files
# Usage: ./upload-wacli-to-r2.sh

set -e

WACLI_DIR="$HOME/.wacli"
R2_BUCKET="moltbot-data"

if [ ! -f "$WACLI_DIR/session.db" ]; then
    echo "Error: $WACLI_DIR/session.db not found"
    echo "Run 'wacli auth' first to authenticate with WhatsApp"
    exit 1
fi

echo "Uploading wacli session files to R2 bucket: $R2_BUCKET"
echo ""

# Upload session.db
echo "Uploading session.db ($(wc -c < "$WACLI_DIR/session.db") bytes)..."
wrangler r2 object put "$R2_BUCKET/wacli/session.db" --file "$WACLI_DIR/session.db"

# Upload wacli.db if it exists
if [ -f "$WACLI_DIR/wacli.db" ]; then
    echo "Uploading wacli.db ($(wc -c < "$WACLI_DIR/wacli.db") bytes)..."
    wrangler r2 object put "$R2_BUCKET/wacli/wacli.db" --file "$WACLI_DIR/wacli.db"
fi

echo ""
echo "Done! Files uploaded to R2."
echo ""
echo "To apply immediately, call the restore endpoint:"
echo "  curl -X POST 'https://moltbot-sandbox.shishirpai001.workers.dev/api/admin/wacli/restore' -H 'Cookie: CF_Authorization=<token>'"
echo ""
echo "Or restart the gateway - the session will be restored on boot."
