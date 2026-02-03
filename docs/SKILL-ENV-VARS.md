# Skill Environment Variables

This document explains how environment variables flow from Cloudflare secrets to skills running inside the container.

## Overview

Skill environment variables go through **4 stages** before they're available to skill scripts:

```
┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐    ┌──────────────────┐
│  1. Wrangler     │    │  2. Worker       │    │  3. Container    │    │  4. Skill        │
│     Secrets      │ ─► │     Passthrough  │ ─► │     Startup      │ ─► │     Scripts      │
│                  │    │                  │    │                  │    │                  │
│  wrangler secret │    │  src/gateway/    │    │  start-moltbot   │    │  scripts/*.sh    │
│  put VAR_NAME    │    │  env.ts          │    │  .sh             │    │                  │
└──────────────────┘    └──────────────────┘    └──────────────────┘    └──────────────────┘
```

## Stage 1: Set Wrangler Secrets

Secrets are stored securely in Cloudflare and injected into the Worker at runtime.

```bash
# Set a secret
npx wrangler secret put OBSIDIAN_API_URL
# Enter value when prompted: https://obsidian.example.com

npx wrangler secret put OBSIDIAN_API_KEY
# Enter value when prompted: your-api-key-here

# Verify secrets are set
npx wrangler secret list
```

**Output:**
```json
[
  { "name": "OBSIDIAN_API_URL", "type": "secret_text" },
  { "name": "OBSIDIAN_API_KEY", "type": "secret_text" }
]
```

## Stage 2: Worker Passthrough

The Worker receives secrets as `env.VAR_NAME`, but the container does NOT automatically receive them. You must explicitly pass each variable.

### 2a. Add to TypeScript types

**File:** `src/types.ts`

```typescript
export interface MoltbotEnv {
  // ... existing vars ...

  // Skill API keys
  OBSIDIAN_API_URL?: string;  // Obsidian skill
  OBSIDIAN_API_KEY?: string;  // Obsidian skill
}
```

### 2b. Add to buildEnvVars function

**File:** `src/gateway/env.ts`

```typescript
export function buildEnvVars(env: MoltbotEnv): Record<string, string> {
  const envVars: Record<string, string> = {};

  // ... existing vars ...

  // Skill API keys - MUST be explicitly passed to container
  if (env.OBSIDIAN_API_URL) envVars.OBSIDIAN_API_URL = env.OBSIDIAN_API_URL;
  if (env.OBSIDIAN_API_KEY) envVars.OBSIDIAN_API_KEY = env.OBSIDIAN_API_KEY;

  return envVars;
}
```

**Why is this needed?** The Worker and Container are separate processes. The Worker acts as a gatekeeper - only variables explicitly added to `buildEnvVars()` are passed to the container.

## Stage 3: Container Startup

The `start-moltbot.sh` script runs when the container starts. It:
1. Reads environment variables
2. Configures the openclaw gateway
3. Writes `.env` files for skills
4. Registers skills in the config

### 3a. Register skill in openclaw config

**File:** `start-moltbot.sh` (inside the Node.js heredoc section)

```javascript
// Obsidian skill (REST API for notes, search, periodic notes)
if (process.env.OBSIDIAN_API_URL && process.env.OBSIDIAN_API_KEY) {
    config.skills = config.skills || {};
    config.skills.entries = config.skills.entries || {};
    config.skills.entries.obsidian = config.skills.entries.obsidian || {};
    config.skills.entries.obsidian.enabled = true;
    config.skills.entries.obsidian.env = {
        OBSIDIAN_API_URL: process.env.OBSIDIAN_API_URL,
        OBSIDIAN_API_KEY: process.env.OBSIDIAN_API_KEY
    };
    console.log('Configured obsidian skill with REST API');
}
```

### 3b. Write to .env files

**File:** `start-moltbot.sh` (in the ENV_LINES section)

```bash
{
    ENV_LINES=""
    # ... other vars ...

    if [ -n "$OBSIDIAN_API_URL" ]; then
        ENV_LINES="${ENV_LINES}OBSIDIAN_API_URL=${OBSIDIAN_API_URL}\n"
        export OBSIDIAN_API_URL
    fi
    if [ -n "$OBSIDIAN_API_KEY" ]; then
        ENV_LINES="${ENV_LINES}OBSIDIAN_API_KEY=${OBSIDIAN_API_KEY}\n"
        export OBSIDIAN_API_KEY
    fi

    if [ -n "$ENV_LINES" ]; then
        printf "$ENV_LINES" > /root/clawd/.env
        printf "$ENV_LINES" > "$CONFIG_DIR/.env"
        echo "Wrote .env files for openclaw env loading"
    fi
}
```

## Stage 4: Skill Scripts

Skill scripts can now access the environment variables directly.

**File:** `skills/obsidian/scripts/status.sh`

```bash
#!/bin/bash
set -e

# Check required env vars
if [ -z "$OBSIDIAN_API_URL" ] || [ -z "$OBSIDIAN_API_KEY" ]; then
    echo "Error: OBSIDIAN_API_URL and OBSIDIAN_API_KEY must be set" >&2
    exit 1
fi

# Use the env vars
curl -s -X GET "${OBSIDIAN_API_URL}/" \
    -H "Authorization: Bearer ${OBSIDIAN_API_KEY}"
```

## Complete Example: Adding a New Skill's Env Vars

Let's say you're adding a new skill called `notion` that needs `NOTION_API_KEY`.

### Step 1: Set the secret

```bash
npx wrangler secret put NOTION_API_KEY
```

### Step 2: Add to types.ts

```typescript
// src/types.ts
export interface MoltbotEnv {
  // ... existing ...
  NOTION_API_KEY?: string;  // Notion skill
}
```

### Step 3: Add to gateway/env.ts

```typescript
// src/gateway/env.ts
export function buildEnvVars(env: MoltbotEnv): Record<string, string> {
  // ... existing ...

  // Notion skill
  if (env.NOTION_API_KEY) envVars.NOTION_API_KEY = env.NOTION_API_KEY;

  return envVars;
}
```

### Step 4: Add to start-moltbot.sh (Node section)

```javascript
// Notion skill
if (process.env.NOTION_API_KEY) {
    config.skills.entries.notion = config.skills.entries.notion || {};
    config.skills.entries.notion.enabled = true;
    config.skills.entries.notion.env = { NOTION_API_KEY: process.env.NOTION_API_KEY };
    console.log('Configured notion skill with API key');
}
```

### Step 5: Add to start-moltbot.sh (ENV_LINES section)

```bash
if [ -n "$NOTION_API_KEY" ]; then
    ENV_LINES="${ENV_LINES}NOTION_API_KEY=${NOTION_API_KEY}\n"
    export NOTION_API_KEY
fi
```

### Step 6: Force container restart and deploy

```bash
# Update CACHE_BUST in Dockerfile
sed -i 's/CACHE_BUST=.*/CACHE_BUST='$(date +%Y-%m-%d-%H%M%S)'/' Dockerfile

# Deploy
npm run deploy
```

## Current Skills and Their Env Vars

| Skill | Environment Variables | Purpose |
|-------|----------------------|---------|
| **obsidian** | `OBSIDIAN_API_URL`, `OBSIDIAN_API_KEY` | Obsidian REST API access |
| **github** | `GH_TOKEN` | GitHub CLI authentication |
| **bird** | `AUTH_TOKEN`, `CT0` | Twitter/X API cookies |
| **goplaces** | `GOOGLE_PLACES_API_KEY` | Google Places API |
| **nia** | `NIA_API_KEY` | Nia knowledge agent |
| **bitwarden** | *(uses interactive login)* | Password manager |

## Debugging Env Var Issues

### Check if secret is set

```bash
npx wrangler secret list
```

### Check Worker logs for skill configuration

```bash
npx wrangler tail --format pretty
```

Look for messages like:
```
Configured obsidian skill with REST API
Configured github skill with token
```

### Check if env var reaches the script

Add debug output to your skill script:

```bash
#!/bin/bash
echo "DEBUG: OBSIDIAN_API_URL=$OBSIDIAN_API_URL" >&2
echo "DEBUG: OBSIDIAN_API_KEY length=${#OBSIDIAN_API_KEY}" >&2
```

### Common Issues

| Problem | Cause | Solution |
|---------|-------|----------|
| Skill says env var not set | Not in `buildEnvVars()` | Add to `src/gateway/env.ts` |
| Skill still not working after adding | Container not restarted | Update `CACHE_BUST`, redeploy |
| Secret not in `wrangler secret list` | Never set | Run `wrangler secret put` |
| Works locally but not in prod | Using `.dev.vars` locally | Set actual wrangler secrets |

## File Reference

| File | Purpose |
|------|---------|
| `src/types.ts` | TypeScript interface for Worker env |
| `src/gateway/env.ts` | Passes env vars from Worker to Container |
| `start-moltbot.sh` | Container startup, skill config, .env files |
| `skills/*/scripts/*.sh` | Skill scripts that use env vars |
| `Dockerfile` | Container image (CACHE_BUST for forcing restart) |
