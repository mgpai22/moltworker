---
slug: obsidian
name: Obsidian
description: Interact with Obsidian vaults via REST API - search, create, read, and manage notes.
homepage: https://github.com/coddingtonbear/obsidian-local-rest-api
---

# Obsidian Skill

Interact with [Obsidian](https://obsidian.md) vaults via the [Local REST API plugin](https://github.com/coddingtonbear/obsidian-local-rest-api). Search, create, read, update, and delete notes remotely.

## Setup

### Environment Variables

| Variable | Description |
|----------|-------------|
| `OBSIDIAN_API_URL` | Base URL of your Obsidian REST API (e.g., `https://obsidian.example.com`) |
| `OBSIDIAN_API_KEY` | API key from the Local REST API plugin |

These should be set via wrangler secrets:
```bash
npx wrangler secret put OBSIDIAN_API_URL
npx wrangler secret put OBSIDIAN_API_KEY
```

## Available Scripts

### Notes - Read
| Script | Description |
|--------|-------------|
| `vault-list.sh [path]` | List files/folders in vault |
| `note-read.sh <path>` | Read note contents |
| `note-read-json.sh <path>` | Read note with metadata (JSON) |
| `search.sh <query>` | Search notes by content |

### Notes - Write
| Script | Description |
|--------|-------------|
| `note-create.sh <path> <content>` | Create a new note |
| `note-update.sh <path> <content>` | Update/overwrite a note |
| `note-append.sh <path> <content>` | Append to a note |
| `note-prepend.sh <path> <content>` | Prepend to a note |
| `note-delete.sh <path>` | Delete a note |

### Commands & Status
| Script | Description |
|--------|-------------|
| `status.sh` | Check API status and authentication |
| `commands-list.sh` | List available Obsidian commands |
| `command-run.sh <command-id>` | Execute an Obsidian command |
| `open.sh <path>` | Open note in Obsidian app |

### Periodic Notes
| Script | Description |
|--------|-------------|
| `daily.sh` | Get/create today's daily note |
| `weekly.sh` | Get/create this week's weekly note |
| `monthly.sh` | Get/create this month's monthly note |

## Examples

### Check API status
```bash
./scripts/status.sh
```

### List vault contents
```bash
./scripts/vault-list.sh
./scripts/vault-list.sh "Projects/"
```

### Read a note
```bash
./scripts/note-read.sh "Ideas/startup-idea.md"
./scripts/note-read-json.sh "Daily/2024-01-15.md"  # includes frontmatter
```

### Create a note
```bash
./scripts/note-create.sh "Notes/meeting.md" "# Meeting Notes

- Item 1
- Item 2"
```

### Append to a note
```bash
./scripts/note-append.sh "Inbox.md" "
- New task added via API"
```

### Search notes
```bash
./scripts/search.sh "project deadline"
```

### Open daily note
```bash
./scripts/daily.sh
```

## API Reference

The Local REST API plugin provides these endpoints:

| Endpoint | Method | Description |
|----------|--------|-------------|
| `/` | GET | API status |
| `/vault/` | GET | List vault root |
| `/vault/{path}` | GET | Read file/list directory |
| `/vault/{path}` | PUT | Create/update file |
| `/vault/{path}` | POST | Append to file |
| `/vault/{path}` | PATCH | Prepend/insert into file |
| `/vault/{path}` | DELETE | Delete file |
| `/search/simple/` | POST | Simple text search |
| `/commands/` | GET | List commands |
| `/commands/{id}` | POST | Execute command |
| `/open/{path}` | POST | Open in Obsidian |
| `/periodic/daily/` | GET | Get daily note |
| `/periodic/weekly/` | GET | Get weekly note |
| `/periodic/monthly/` | GET | Get monthly note |

## Notes

- Paths are relative to vault root
- Include `.md` extension for markdown files
- Use forward slashes: `folder/subfolder/note.md`
