---
title: Upstream Merge Causes Cascading Deploy Failures
category: integration-issues
component: worker, gateway, container
symptoms:
  - "Configuration Required" page after deploy
  - Exit code 127 (command not found) in container
  - Exit code 1 (config validation failure)
  - WebSocket 1008 "Invalid or missing token"
root_cause: Blind merge conflict resolution accepting upstream changes without validating against local setup
date: 2026-02-09
severity: high
---

# Upstream Merge Causes Cascading Deploy Failures

## Problem

After merging 28 upstream commits into a fork with 22 local commits, deploying resulted in 4 cascading failures that had to be debugged sequentially.

## Symptoms

1. **"Configuration Required" page** - Worker env validation rejected the deployment
2. **Exit code 127** - Container couldn't find the startup script
3. **Exit code 1** - OpenClaw config validation failed on startup
4. **WebSocket 1008** - "Invalid or missing token" on all WS connections

## Root Cause Analysis

### Failure 1: Env Validation Mismatch
Accepting upstream's `src/index.ts` during merge resolution introduced validation logic checking for `CLOUDFLARE_AI_GATEWAY_API_KEY`, while the local setup uses `ANTHROPIC_API_KEY`, `ANTHROPIC_OAUTH_TOKEN`, `OPENAI_API_KEY`, or `AI_GATEWAY_API_KEY`.

**Fix:** Updated validation in `src/index.ts` to check for the correct env vars and added missing vars to `MoltbotEnv` type in `src/types.ts`.

### Failure 2: Script Name Mismatch
Upstream renamed `start-moltbot.sh` to `start-openclaw.sh` in `src/gateway/process.ts`, but the Dockerfile still copies `start-moltbot.sh`. The merge brought in code referencing the new name while the Dockerfile kept the old name.

**Fix:** Updated `src/gateway/process.ts` to reference `start-moltbot.sh`.

### Failure 3: Leading Spaces in Cloudflare Secrets
Cloudflare secret values had leading spaces (e.g., `" allowlist"` instead of `"allowlist"`). OpenClaw's strict config validation rejected these as invalid enum values.

**Fix:** Added `.trim()` calls in `start-moltbot.sh` for all policy and token values read from env.

### Failure 4: WebSocket Auth Broke
Two separate WebSocket auth pitfalls can show up after deploys/merges:

1. **`sandbox.wsConnect()` query params**: `wsConnect()` may drop URL query parameters unless you construct an explicit
   localhost URL (`http://localhost:18789<path><search>`) for the container request.
2. **Control UI auth location**: modern OpenClaw Control UI sends auth in the WebSocket `connect` request payload
   (`params.auth.token`). Injecting a `token` field in the wrong place is rejected as an "unexpected property".

**Fix:** Use an explicit localhost URL for `wsConnect()` when you need query params, and for Control UI specifically,
inject `params.auth.token` server-side (or ensure the UI settings token is set). See:
- `docs/solutions/integration-issues/control-ui-ws-auth-connect-frame-token-injection.md`
- `docs/solutions/integration-issues/sandbox-wsconnect-query-param-forwarding.md`

## Solution

Each failure required a targeted fix (see above). The key insight is that these were all caused by a single root action: blindly accepting "theirs" during merge conflict resolution.

## Prevention

1. **Never blindly accept "theirs" for merge conflicts** - Review each conflict individually, especially in entry points (`index.ts`), type definitions, and configuration files
2. **Always trim env var values from Cloudflare secrets** - Add `.trim()` defensively when reading secrets
3. **After merging upstream, verify script/binary name references match** - Check that Dockerfile, process.ts, and startup scripts all agree on filenames
4. **Test deploy after merge before committing more changes** - Deploy immediately after merge to catch failures early rather than stacking changes

## Related

- `AGENTS.md` → "Environment Variables" section
- `AGENTS.md` → "Gateway Token Mismatch" troubleshooting
- `docs/DEPLOYMENT.md`
