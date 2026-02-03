---
slug: imgbb
name: ImgBB
description: Upload images to ImgBB from the agent with optional API key support.
homepage: https://github.com/wabarc/imgbb
---

# ImgBB Skill

Upload local image files to [ImgBB](https://imgbb.com) using the official `imgbb` CLI. Supports anonymous uploads or authenticated uploads with an API key.

## Setup

- Optional: create an ImgBB API key (Dashboard → Settings → API → Create API key) and set `IMGBB_API_KEY`.
- Without a key, uploads use the public endpoint but still work for files up to 32 MB.

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `IMGBB_API_KEY` | No | ImgBB API key for authenticated uploads (improves reliability; anonymous uploads are allowed if unset). |

## Available Scripts

### `upload.sh <file1> [file2 ...] [--json]`
Upload one or more images. Uses `IMGBB_API_KEY` if set, otherwise falls back to anonymous uploads.

#### Examples

```bash
# Anonymous upload
./scripts/upload.sh ./images/cat.png

# Authenticated upload with JSON output
IMGBB_API_KEY=sk-123 ./scripts/upload.sh photo.jpg screenshot.png --json
```

## Notes

- Maximum file size is 32 MB (enforced by the CLI).
- The script prints `URL<TAB>FILE` by default; `--json` returns a JSON array of `{ url, file }` objects.
