# Deployment & Restart Guide

This document explains how deploying and restarting works for moltworker, which uses Cloudflare Workers with Containers (Sandbox).

## Architecture Overview

```
┌─────────────────────────────────────────────────────────────┐
│                    Cloudflare Edge                          │
│  ┌─────────────────┐      ┌─────────────────────────────┐  │
│  │  Worker (JS)    │ ───► │  Container (Docker)         │  │
│  │                 │      │                             │  │
│  │  - Routes       │      │  - start-moltbot.sh         │  │
│  │  - Auth         │      │  - openclaw gateway         │  │
│  │  - Env vars     │      │  - Skills (scripts)         │  │
│  │  - buildEnvVars │      │  - CLI tools (gh, bw, etc)  │  │
│  └─────────────────┘      └─────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

**Two separate components:**
1. **Worker** (`src/`) - JavaScript code running on Cloudflare edge
2. **Container** (`Dockerfile`) - Docker container running the bot

## What `npm run deploy` Does

```bash
npm run deploy
# Equivalent to: npm run build && wrangler deploy
```

### Step 1: Build Worker
Vite compiles TypeScript in `src/` to JavaScript bundles in `dist/`.

### Step 2: Upload Worker
Wrangler uploads the Worker code to Cloudflare.

### Step 3: Build Container Image
Docker builds the image from `Dockerfile`. Uses layer caching - unchanged layers are reused.

### Step 4: Push Container Image
If the image hash changed, it's pushed to Cloudflare's container registry.

### Step 5: Update Container Config
If a new image was pushed, Cloudflare updates the container configuration.

## When Does the Container Restart?

### Container WILL restart when:
- **New image hash** - Any change to Dockerfile or files COPYed into it
- **First request after deploy** - Container starts lazily on first request

### Container will NOT restart when:
- **Only Worker code changed** - Container keeps running with old image
- **Image hash unchanged** - Docker cache hit, same image reused

## Environment Variables Flow

```
Wrangler Secrets          Worker (env.ts)           Container
─────────────────    ───────────────────────    ─────────────────
OBSIDIAN_API_URL  →  buildEnvVars() adds it  →  process.env.OBSIDIAN_API_URL
OBSIDIAN_API_KEY  →  to container startup    →  process.env.OBSIDIAN_API_KEY
```

**Critical:** Secrets set via `wrangler secret put` are available in the Worker, but must be explicitly passed to the container in `src/gateway/env.ts`:

```typescript
// src/gateway/env.ts
export function buildEnvVars(env: MoltbotEnv): Record<string, string> {
  const envVars: Record<string, string> = {};

  // Must explicitly pass each env var to container
  if (env.OBSIDIAN_API_URL) envVars.OBSIDIAN_API_URL = env.OBSIDIAN_API_URL;
  if (env.OBSIDIAN_API_KEY) envVars.OBSIDIAN_API_KEY = env.OBSIDIAN_API_KEY;

  return envVars;
}
```

## How to Force a Container Restart

### Method 1: Change CACHE_BUST (Recommended)

Edit `Dockerfile`:
```dockerfile
# Change this value to force rebuild
ARG CACHE_BUST=2026-02-03-v2  # Increment version
```

Then deploy:
```bash
npm run deploy
```

### Method 2: Touch a COPYed file

Any change to files that are COPYed into the container will invalidate the cache:
- `start-moltbot.sh`
- `moltbot.json.template`
- `skills/` directory

### Method 3: Modify Dockerfile

Any change to Dockerfile instructions after the cached layers.

## Verifying Deployment

### Check if container restarted

Look for these in deploy output:
```
# Container DID restart:
├ EDIT moltbot-sandbox-sandbox
│ -  "image": "...sandbox:OLD_HASH",
│ +  "image": "...sandbox:NEW_HASH",
│  SUCCESS  Modified application

# Container did NOT restart:
├ no changes moltbot-sandbox-sandbox
╰ No changes to be made
```

### Check logs for restart confirmation

```bash
npx wrangler tail --format json
```

Look for:
```json
{"message": "Runtime signalled the container to exit due to a new version rollout"}
{"message": "Durable Object reset because its code was updated"}
```

### Trigger container start

The container starts lazily. Make a request to trigger it:
```bash
curl https://moltbot-sandbox.shishirpai001.workers.dev/
```

## Common Scenarios

### Scenario 1: Added new wrangler secret

```bash
# 1. Set the secret
npx wrangler secret put NEW_SECRET

# 2. Add to types.ts
NEW_SECRET?: string;

# 3. Add to gateway/env.ts buildEnvVars()
if (env.NEW_SECRET) envVars.NEW_SECRET = env.NEW_SECRET;

# 4. Add to start-moltbot.sh if skill needs it
if [ -n "$NEW_SECRET" ]; then
    ENV_LINES="${ENV_LINES}NEW_SECRET=${NEW_SECRET}\n"
fi

# 5. Force container restart (change CACHE_BUST)
# 6. Deploy
npm run deploy
```

### Scenario 2: Updated skill scripts only

```bash
# Skills are in skills/ which is COPYed to container
# Any change will trigger new image

npm run deploy  # Will rebuild container
```

### Scenario 3: Changed Worker code only (no container changes)

```bash
npm run deploy
# Worker updates immediately
# Container keeps running (no restart needed if env passthrough unchanged)
```

### Scenario 4: Need container restart but no code changes

```bash
# Edit Dockerfile CACHE_BUST
sed -i 's/CACHE_BUST=.*/CACHE_BUST='$(date +%Y-%m-%d-%H%M)'/' Dockerfile
npm run deploy
```

## Troubleshooting

### Container not picking up new env vars

1. Verify secret is set: `npx wrangler secret list`
2. Check `src/gateway/env.ts` passes it to container
3. Check `src/types.ts` has the type definition
4. Force container restart with CACHE_BUST change

### Deploy says "no changes" but I changed code

- Worker code: Check `dist/` was rebuilt
- Container: The image hash is based on content, not timestamps

### Container keeps crashing

Check logs:
```bash
npx wrangler tail --format pretty
```

Common issues:
- Missing env vars
- Syntax errors in start-moltbot.sh
- Port conflicts (gateway must be on 18789)

## Quick Reference

| Task | Command |
|------|---------|
| Deploy everything | `npm run deploy` |
| List secrets | `npx wrangler secret list` |
| Add secret | `npx wrangler secret put SECRET_NAME` |
| View logs | `npx wrangler tail --format pretty` |
| Force restart | Edit `CACHE_BUST` in Dockerfile, then deploy |
