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

## What Persists in R2

When R2 is configured, the cron sync backs up and restores the following paths:

- `/root/.openclaw/` (includes `workspace/` for agent files like `memory/`, `TOOLS.md`, `tov/`)
- `/root/clawd/skills/`
- `/root/.wacli/` (WhatsApp session files, if present in R2)

Anything outside these paths is not persisted across container restarts.

## How to Force a Container Restart

### Method 0: `/api/status` Reset (Fastest)

The Worker exposes a public reset mechanism on the status endpoint:

```bash
curl "https://your-worker.workers.dev/api/status?reset=<MOLTBOT_GATEWAY_TOKEN>"
```

This destroys the Sandbox container. The next request will create a fresh container with the latest image.

Then poll until it reports running:

```bash
curl "https://your-worker.workers.dev/api/status"
```

Security note: the reset token is the same value as `MOLTBOT_GATEWAY_TOKEN`. Treat it as sensitive.

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

## Programmatic Gateway Restart

If you want to restart the gateway from automation (CI, cron, external scripts), you have two options:

1. Cloudflare Access service tokens (recommended if Access is enforced at the edge).
2. A worker-level bearer token via `ADMIN_API_TOKEN` (simpler, but only works if the request can reach the Worker).

### Option A: Worker-level bearer token (`ADMIN_API_TOKEN`)

1. Set the secret:
```bash
npx wrangler secret put ADMIN_API_TOKEN
```

2. Restart the gateway:
```bash
curl -X POST "https://your-worker.workers.dev/api/admin/gateway/restart" \
  -H "Authorization: Bearer $ADMIN_API_TOKEN"
```

### Option B: Cloudflare Access service token headers

If Cloudflare Access is configured to protect your Worker domain/path at the edge, requests may be blocked before they reach the Worker. In that case, use Access service tokens:
```bash
curl -X POST "https://your-worker.workers.dev/api/admin/gateway/restart" \
  -H "CF-Access-Client-Id: $CF_ACCESS_CLIENT_ID" \
  -H "CF-Access-Client-Secret: $CF_ACCESS_CLIENT_SECRET"
```

### Option C: Manually bypass Cloudflare Access for only the restart route

If you want `/api/admin/gateway/restart` to be reachable without Cloudflare Access (and rely on `ADMIN_API_TOKEN` in the Worker instead), create a dedicated Access application for that single path with a `bypass` policy.

1. Cloudflare Zero Trust dashboard: **Access** -> **Applications** -> **Add an application** -> **Self-hosted**.
2. Application domain: your worker host (example: `moltbot-sandbox.<subdomain>.workers.dev`).
3. Paths: add exactly `/api/admin/gateway/restart`.
4. Policies: add a policy with **Action** = `Bypass` and **Include** = `Everyone`.
5. Save.

Security note: if you bypass Access, the restart endpoint is protected only by `ADMIN_API_TOKEN`. Use a long random token and rotate it.

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

## Debugging Container Startup Issues

### Container Cold Start Time

**The container takes 30-60 seconds to fully start.** This is normal for Cloudflare Sandbox containers.

During startup:
- `/api/status` returns `{"ok":false,"status":"starting"}`
- Requests to container ports return `Error proxying request to container: The container is not listening`
- After startup, `/api/status` returns `{"ok":true,"status":"running"}`

### Rapid Deployments Problem

**Symptom:** Container never starts, stays in "starting" state indefinitely.

**Cause:** Each `wrangler deploy` with a new container image:
1. Stops the old container
2. Pulls the new image
3. Starts a new container from scratch

If you deploy again before the container finishes starting (~60s), you interrupt the boot cycle and it never completes.

**Solution:**
- Wait at least 90 seconds between deployments that change the container
- If stuck, stop deploying and wait 2-3 minutes for the container to fully start
- Use `npx wrangler tail --format pretty` to monitor real-time logs

### The 90-Second Cooldown

The `/api/status` endpoint has a 90-second cooldown to prevent multiple gateway start attempts:

```typescript
const GATEWAY_START_COOLDOWN_MS = 90_000;
```

This cooldown is **in-memory** and resets when:
- The Worker's Durable Object restarts (happens on new container deploys)
- The Worker code is updated

**Debugging tip:** If the container seems stuck, the cooldown may be active. Wait for it to expire or trigger a fresh start by visiting the main site with authentication.

### Checking Container State

```bash
# Check if gateway port (18789) is responding
curl -s https://moltbot-sandbox.shishirpai001.workers.dev/api/status

# If voice-call plugin is enabled, check webhook port (3334)
curl -s -X POST https://moltbot-sandbox.shishirpai001.workers.dev/voice/webhook -d "test=1"

# Expected responses:
# - Gateway running: {"ok":true,"status":"running"}
# - Gateway starting: {"ok":false,"status":"starting"}
# - Voice webhook (no sig): "Unauthorized" (means plugin is running)
# - Container not ready: "Error proxying request to container..."
```

### Real-Time Log Monitoring

```bash
# Start tail in one terminal
npx wrangler tail --format pretty

# Make a request in another terminal
curl https://moltbot-sandbox.shishirpai001.workers.dev/api/status

# Look for:
# [status] Port up! status: 200          → Gateway running
# [status] Cooldown active, remaining: X → In cooldown period
# [status] Gateway not responding...     → Starting gateway
```

### Common Startup Failures

| Symptom | Likely Cause | Fix |
|---------|--------------|-----|
| Stays "starting" forever | Rapid redeployments | Stop deploying, wait 2-3 min |
| "Container not listening" | Gateway failed to start | Check `start-moltbot.sh` syntax |
| Immediate crash | Config parsing error | Validate JS in heredoc with `node --check` |
| Port 18789 not responding | Gateway error | Check wrangler tail for errors |

### R2 Config Backup Issues

The gateway syncs config to R2. Old backups can override fresh deployments.

**To force fresh config:**
```bash
# Delete the R2 backup before deploying
npx wrangler r2 object delete moltbot-sandbox-backup/openclaw/openclaw.json --remote
npx wrangler r2 object delete moltbot-sandbox-backup/.last-sync --remote

# Then deploy
npm run deploy
```

### Recovery Procedure

If the container is completely stuck:

1. **Stop making changes** - Let the current state settle
2. **Wait 2-3 minutes** - Allow any in-progress startup to complete
3. **Clear R2 backup** (if config issues):
   ```bash
   npx wrangler r2 object delete moltbot-sandbox-backup/openclaw/openclaw.json --remote
   ```
4. **Bump CACHE_BUST** and deploy once:
   ```bash
   # Increment version in Dockerfile
   npm run deploy
   ```
5. **Wait 90 seconds** - Don't make any more changes
6. **Verify with tail**:
   ```bash
   npx wrangler tail --format pretty
   # Then trigger a request
   ```

## Quick Reference

| Task | Command |
|------|---------|
| Deploy everything | `npm run deploy` |
| List secrets | `npx wrangler secret list` |
| Add secret | `npx wrangler secret put SECRET_NAME` |
| View logs | `npx wrangler tail --format pretty` |
| Force restart | Edit `CACHE_BUST` in Dockerfile, then deploy |
| Clear R2 config | `npx wrangler r2 object delete moltbot-sandbox-backup/openclaw/openclaw.json --remote` |
| Check container status | `curl https://moltbot-sandbox.shishirpai001.workers.dev/api/status` |
