---
slug: whatsapp
name: WhatsApp
description: WhatsApp CLI for syncing, searching, and sending messages via wacli
version: 1.0.0
enabled: true
tools:
  # Authentication
  - name: wa-auth
    description: "Authenticate with WhatsApp (shows QR code to scan)"
    script: scripts/auth.sh
  - name: wa-auth-status
    description: "Check WhatsApp authentication status"
    script: scripts/auth-status.sh
  - name: wa-logout
    description: "Log out from WhatsApp"
    script: scripts/logout.sh
  # Sync
  - name: wa-sync
    description: "Sync WhatsApp messages (requires prior auth)"
    script: scripts/sync.sh
  - name: wa-doctor
    description: "Run WhatsApp CLI diagnostics"
    script: scripts/doctor.sh
  # Messages
  - name: wa-messages-list
    description: "List messages from a chat"
    script: scripts/messages-list.sh
  - name: wa-messages-search
    description: "Search messages with full-text search"
    script: scripts/messages-search.sh
  - name: wa-messages-show
    description: "Show a specific message"
    script: scripts/messages-show.sh
  - name: wa-messages-context
    description: "Show messages around a specific message"
    script: scripts/messages-context.sh
  # Send
  - name: wa-send-text
    description: "Send a text message"
    script: scripts/send-text.sh
  - name: wa-send-file
    description: "Send a file (image, document, etc.)"
    script: scripts/send-file.sh
  # Chats
  - name: wa-chats-list
    description: "List all chats"
    script: scripts/chats-list.sh
  - name: wa-chats-show
    description: "Show chat details"
    script: scripts/chats-show.sh
  # Contacts
  - name: wa-contacts-search
    description: "Search contacts"
    script: scripts/contacts-search.sh
  - name: wa-contacts-show
    description: "Show contact details"
    script: scripts/contacts-show.sh
  - name: wa-contacts-refresh
    description: "Refresh contacts from WhatsApp"
    script: scripts/contacts-refresh.sh
  # Groups
  - name: wa-groups-list
    description: "List all groups"
    script: scripts/groups-list.sh
  - name: wa-groups-info
    description: "Show group information"
    script: scripts/groups-info.sh
  - name: wa-groups-rename
    description: "Rename a group"
    script: scripts/groups-rename.sh
  - name: wa-groups-participants
    description: "Manage group participants (add/remove/promote/demote)"
    script: scripts/groups-participants.sh
  # History
  - name: wa-history-backfill
    description: "Backfill older messages from a chat"
    script: scripts/history-backfill.sh
  # Media
  - name: wa-media-download
    description: "Download media from a message"
    script: scripts/media-download.sh
---

# WhatsApp CLI (wacli)

WhatsApp CLI for syncing, searching, and sending messages. Built on `whatsmeow` using the WhatsApp Web protocol.

## Authentication for Moltbot Container

The moltbot container runs in Cloudflare's infrastructure where you can't scan a QR code directly. Instead, you authenticate locally and transfer the session to the cloud via R2 storage.

### Architecture Overview

```
┌─────────────────┐     ┌─────────────────┐     ┌─────────────────┐
│  Local Machine  │     │   Cloudflare    │     │    Moltbot      │
│                 │     │       R2        │     │   Container     │
│  ~/.wacli/      │────▶│  moltbot-data/  │────▶│  /root/.wacli/  │
│  session.db     │     │  wacli/         │     │  session.db     │
│  wacli.db       │     │  session.db     │     │  wacli.db       │
└─────────────────┘     │  wacli.db       │     └─────────────────┘
     QR scan            └─────────────────┘          rsync
```

### Prerequisites

1. **wacli installed locally** - Install from https://github.com/anthropics/wacli
   ```bash
   # macOS
   brew install wacli

   # Or build from source
   go install github.com/anthropics/wacli@latest
   ```

2. **wrangler CLI** - Cloudflare's CLI tool for R2 uploads
   ```bash
   npm install -g wrangler
   wrangler login  # Authenticate with your Cloudflare account
   ```

3. **R2 credentials configured** in the Worker (already done if moltbot is deployed):
   - `R2_ACCESS_KEY_ID`
   - `R2_SECRET_ACCESS_KEY`
   - `CF_ACCOUNT_ID`

### Step 1: Authenticate Locally

Run wacli on your local machine to scan the QR code:

```bash
# Start authentication - displays QR code in terminal
wacli auth
```

On your phone:
1. Open WhatsApp
2. Go to **Settings** → **Linked Devices**
3. Tap **Link a Device**
4. Scan the QR code displayed in your terminal

The QR code expires in ~60 seconds. If it expires, press Enter to generate a new one.

After scanning, wacli will sync your messages. Wait for the initial sync to complete:

```bash
# Verify authentication succeeded
wacli auth status
# Should output: "Authenticated."

# Check that messages synced
wacli chats list --limit 5
```

### Step 2: Upload Session to R2

Your session is stored in `~/.wacli/`. Upload it to R2:

**Option A: Use the helper script** (recommended)
```bash
cd /path/to/moltworker
./scripts/upload-wacli-to-r2.sh
```

**Option B: Manual upload with wrangler**
```bash
# Upload session.db (required - contains auth keys)
wrangler r2 object put moltbot-data/wacli/session.db --file ~/.wacli/session.db

# Upload wacli.db (optional but recommended - contains message history)
wrangler r2 object put moltbot-data/wacli/wacli.db --file ~/.wacli/wacli.db
```

### Step 3: Restore Session in Container

After uploading to R2, restore the session in the running container:

```bash
# Get your CF_Authorization token:
# 1. Open https://moltbot-sandbox.shishirpai001.workers.dev in browser
# 2. Authenticate via Cloudflare Access
# 3. Open DevTools → Application → Cookies → Copy CF_Authorization value

# Call the restore endpoint
curl -X POST "https://moltbot-sandbox.shishirpai001.workers.dev/api/admin/wacli/restore" \
  -H "Cookie: CF_Authorization=<your-jwt-token>" \
  -H "Content-Type: application/json"
```

Expected response:
```json
{
  "success": true,
  "r2_sizes": "1691648\n3080192\n",
  "rsync_output": "sending incremental file list\n...",
  "local_sizes": "1691648\n3080192\n",
  "wacli_status": "Authenticated.\n"
}
```

### Step 4: Verify It Works

Check the status via API:

```bash
curl "https://moltbot-sandbox.shishirpai001.workers.dev/api/admin/wacli/status" \
  -H "Cookie: CF_Authorization=<your-jwt-token>"
```

Or ask the agent to check:
> "Check if WhatsApp is authenticated"

The agent can now use WhatsApp commands like:
- List chats: `wacli chats list`
- Search messages: `wacli messages search "keyword"`
- Send messages: `wacli send text --to <number> --message "Hello"`

### Troubleshooting

#### "Not authenticated" after restore

**Check file sizes match:**
```bash
curl "https://moltbot-sandbox.shishirpai001.workers.dev/api/admin/wacli/debug" \
  -H "Cookie: CF_Authorization=<token>"
```

The `r2_wacli` and `local_wacli` sizes should match. If local is smaller, the restore failed - try again.

**Re-run restore:**
```bash
curl -X POST ".../api/admin/wacli/restore" -H "Cookie: CF_Authorization=<token>"
```

#### Session expired / logged out

WhatsApp sessions can expire if:
- You manually logged out the device from WhatsApp settings
- The session was inactive for too long
- WhatsApp invalidated the session

**Fix:** Re-authenticate locally and re-upload:
```bash
# On your local machine
wacli auth logout  # Clear old session
wacli auth         # Scan new QR code

# Upload new session
wrangler r2 object put moltbot-data/wacli/session.db --file ~/.wacli/session.db
wrangler r2 object put moltbot-data/wacli/wacli.db --file ~/.wacli/wacli.db

# Restore in container
curl -X POST ".../api/admin/wacli/restore" -H "Cookie: CF_Authorization=<token>"
```

#### Container restarted and lost session

The container automatically restores from R2 on boot using rsync. If it didn't work:

1. Check R2 has the files:
   ```bash
   wrangler r2 object list moltbot-data --prefix wacli/
   ```

2. Manually trigger restore:
   ```bash
   curl -X POST ".../api/admin/wacli/restore" -H "Cookie: CF_Authorization=<token>"
   ```

#### "Phone must be online" errors

Your primary WhatsApp device (phone) must have internet connectivity for:
- Initial sync after authentication
- History backfill requests
- Sending messages to new contacts

The phone does NOT need to be online for:
- Receiving messages (after initial sync)
- Searching cached messages
- Reading cached message history

### API Reference

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/api/admin/wacli/status` | GET | Check if wacli is authenticated |
| `/api/admin/wacli/restore` | POST | Restore session from R2 to container |
| `/api/admin/wacli/debug` | GET | Show R2 vs local file sizes for debugging |

### Session Persistence

- **R2 storage**: Sessions uploaded to R2 persist indefinitely
- **Container local**: Sessions restored to container persist until container restarts
- **Auto-restore**: On container boot, sessions are automatically restored from R2 via rsync

### Security Notes

- The session files contain your WhatsApp encryption keys - treat them as sensitive
- R2 bucket should have restricted access (already configured via Worker bindings)
- Don't share session files or commit them to git
- Logging out from WhatsApp app invalidates the session everywhere

---

## Local Authentication (for development)

If you're running wacli directly (not in moltbot container):

```bash
# Start authentication (displays QR code)
wacli auth

# Scan the QR code with WhatsApp on your phone:
#    WhatsApp > Settings > Linked Devices > Link a Device

# After scanning, wacli will sync your messages automatically
```

### Check Status

```bash
wacli auth status
```

### Logout

```bash
wacli auth logout
```

## Syncing Messages

After authentication, you can sync messages:

```bash
# One-time sync
wacli sync --once

# Continuous sync (stays connected)
wacli sync --follow
```

**Important**: Your primary phone must be online for syncing to work.

## Searching Messages

Fast full-text search using SQLite FTS5:

```bash
# Search all messages
wacli messages search "meeting tomorrow"

# Search in specific chat
wacli messages search "project" --chat 1234567890@s.whatsapp.net

# Search with filters
wacli messages search "photo" --type image --after 2024-01-01
```

## Sending Messages

```bash
# Send text
wacli send text --to 1234567890 --message "Hello!"

# Send to group
wacli send text --to 123456789@g.us --message "Hello group!"

# Send file
wacli send file --to 1234567890 --file ./photo.jpg --caption "Check this out"

# Send document with custom filename
wacli send file --to 1234567890 --file /tmp/report --filename report.pdf
```

## Listing Chats and Messages

```bash
# List all chats
wacli chats list

# List messages from a chat
wacli messages list --chat 1234567890@s.whatsapp.net --limit 50

# Show specific message
wacli messages show --chat 1234567890@s.whatsapp.net --id ABC123
```

## Groups

```bash
# List groups
wacli groups list

# Group info
wacli groups info --jid 123456789@g.us

# Rename group
wacli groups rename --jid 123456789@g.us --name "New Group Name"

# Add participant
wacli groups participants add --jid 123456789@g.us --user 1234567890

# Remove participant
wacli groups participants remove --jid 123456789@g.us --user 1234567890
```

## Contacts

```bash
# Search contacts
wacli contacts search "John"

# Show contact
wacli contacts show --jid 1234567890@s.whatsapp.net

# Refresh contacts
wacli contacts refresh
```

## History Backfill

Fetch older messages (best-effort, requires phone online):

```bash
# Backfill one chat
wacli history backfill --chat 1234567890@s.whatsapp.net --requests 10 --count 50

# Backfill all chats
wacli --json chats list --limit 100000 | jq -r '.[].JID' | while read -r jid; do
  wacli history backfill --chat "$jid" --requests 3 --count 50
done
```

## Media Download

```bash
# Download media from a message
wacli media download --chat 1234567890@s.whatsapp.net --id <message-id>
```

## Storage

Data is stored in `~/.wacli/`:
- `session.db` - WhatsApp session (keys, identity)
- `wacli.db` - Messages, chats, contacts (with FTS5 index)
- `media/` - Downloaded media files

## Environment Variables

| Variable | Description |
|----------|-------------|
| `WACLI_DEVICE_LABEL` | Custom device label shown in WhatsApp |
| `WACLI_DEVICE_PLATFORM` | Device platform (default: CHROME) |

## JID Format

- **Users**: `1234567890@s.whatsapp.net` (phone number without + or country code formatting)
- **Groups**: `123456789@g.us`

## Group Messages: Finding Who Sent What

**CRITICAL**: The `wacli messages list` command's FROM column shows the **group JID** for all group messages, NOT the individual sender. This is a common source of confusion.

### Wrong approach (will fail):
```bash
# This shows the GROUP JID in FROM column, not individual senders
wacli messages list --chat 123456789@g.us --limit 50
# Output: FROM column shows "123456789@g.us" for ALL messages
```

### Correct approach to find messages from a specific person in a group:

**Option 1: Use `messages show` on individual messages**
```bash
# First, list recent message IDs
wacli messages list --chat 123456789@g.us --limit 20

# Then inspect each message to see the actual sender
wacli messages show --chat 123456789@g.us --id <message-id>
# The output will include "Sender" or "SenderJID" field showing who sent it
```

**Option 2: Use JSON output and filter by sender**
```bash
# Get messages as JSON and look at the Sender/SenderJID field
wacli --json messages list --chat 123456789@g.us --limit 50

# The JSON includes sender information that the table view hides
# Look for "Sender" or "SenderJID" fields in the JSON output
```

**Option 3: Search with sender context**
```bash
# Search for content, then use messages show to verify sender
wacli messages search "keyword" --chat 123456789@g.us

# For each result, check the sender with messages show
wacli messages show --chat 123456789@g.us --id <message-id>
```

### Finding a participant's JID in a group

```bash
# List group participants to find someone's JID
wacli groups info --jid 123456789@g.us

# Or search contacts
wacli contacts search "Mom"
```

## Tips

1. **Phone must be online**: Your primary WhatsApp device needs internet for syncing and history backfill.

2. **QR expires quickly**: The QR code expires in ~60 seconds. If it expires, restart `wacli auth`.

3. **Message sync is best-effort**: WhatsApp doesn't guarantee full history. Recent messages sync reliably.

4. **Rate limits**: Don't send too many messages too quickly to avoid being flagged.

5. **One instance at a time**: Only run one wacli instance per WhatsApp account to avoid session conflicts.

6. **Group message senders**: The table view of `messages list` doesn't show individual senders in groups. Always use `messages show` or JSON output to identify who sent a message in a group chat.
