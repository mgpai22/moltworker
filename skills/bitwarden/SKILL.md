---
slug: bitwarden
name: Bitwarden
description: Securely manage passwords, credentials, and secrets with the Bitwarden CLI.
homepage: https://bitwarden.com
---

# Bitwarden Skill

Secure credential management using the [Bitwarden CLI](https://bitwarden.com/help/cli/). Access your vault to retrieve passwords, generate secure credentials, and manage secrets.

## Setup

1. **Login to Bitwarden**: Run `bw login` to authenticate with your Bitwarden account
2. **Unlock your vault**: Run `bw unlock` to get a session key
3. **Set the session**: Export the session key: `export BW_SESSION="your_session_key"`

For API key authentication (recommended for automation):
```bash
export BW_CLIENTID="your_client_id"
export BW_CLIENTSECRET="your_client_secret"
bw login --apikey
```

## Available Scripts

### Authentication & Session
- `login.sh` - Log into Bitwarden account
- `logout.sh` - Log out of current session
- `unlock.sh` - Unlock vault and get session key
- `lock.sh` - Lock vault and destroy session
- `status.sh` - Show vault and sync status
- `sync.sh` - Sync vault with server

### Vault Operations
- `list-items.sh [search]` - List vault items with optional search
- `list-folders.sh` - List all folders
- `list-collections.sh` - List all collections
- `get-item.sh <id|name>` - Get item by ID or name
- `get-password.sh <name>` - Get password for a site/service
- `get-username.sh <name>` - Get username for a site/service
- `get-totp.sh <name>` - Get TOTP code for a site/service
- `get-notes.sh <name>` - Get secure notes for an item

### Create & Edit
- `create-login.sh` - Create a new login item
- `create-note.sh` - Create a secure note
- `create-folder.sh <name>` - Create a new folder
- `edit-item.sh <id>` - Edit an existing item
- `delete-item.sh <id>` - Delete an item (moves to trash)
- `restore-item.sh <id>` - Restore item from trash

### Password Generation
- `generate.sh [options]` - Generate secure password
- `generate-passphrase.sh` - Generate a passphrase

### Import/Export
- `export.sh [format]` - Export vault (json, csv, encrypted_json)
- `import.sh <format> <file>` - Import from file

### Send (Secure Sharing)
- `send-text.sh <text>` - Create a text Send
- `send-file.sh <file>` - Create a file Send
- `receive.sh <url>` - Receive a Send

## Examples

### Get a password
```bash
# By name search
./scripts/get-password.sh "github.com"

# By exact ID
./scripts/get-item.sh "99ee88d2-6046-4ea7-92c2-acac464b1412"
```

### Generate a secure password
```bash
# Default: 18 chars with lowercase, uppercase, special, numbers
./scripts/generate.sh

# Custom: 24 chars, no special characters
./scripts/generate.sh -l -u -n --length 24
```

### List items matching a search
```bash
./scripts/list-items.sh "google"
```

### Create a secure text Send
```bash
./scripts/send-text.sh "Secret message to share"
```

## Environment Variables

| Variable | Description |
|----------|-------------|
| `BW_SESSION` | Session key from `bw unlock` |
| `BW_CLIENTID` | API client ID for automation |
| `BW_CLIENTSECRET` | API client secret for automation |
| `BW_SERVER` | Custom server URL (self-hosted) |

## Tips

- Always use `--raw` flag when scripting to get clean output
- Use `--nointeraction` for automated scripts
- Session keys expire after inactivity - re-unlock as needed
- Use `bw sync` to pull latest vault changes from server
