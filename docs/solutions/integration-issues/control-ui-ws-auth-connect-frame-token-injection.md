---
title: Control UI WebSocket Auth Requires `connect`-Frame Token Injection Behind Worker
category: integration-issues
component: src/index.ts, start-moltbot.sh, Cloudflare Access
symptoms:
  - WebSocket 1008 "Invalid or missing token"
  - WebSocket 1008 "origin not allowed"
  - Control UI prompts for a token even though Worker has MOLTBOT_GATEWAY_TOKEN
root_cause: OpenClaw Control UI authenticates via `connect` request payload (`params.auth.token`) and enforces an Origin allowlist; URL query params alone are insufficient behind CF Access redirects.
date: 2026-02-10
severity: high
---

# Control UI WebSocket Auth Requires `connect`-Frame Token Injection Behind Worker

## Problem

When proxying the OpenClaw Control UI through a Cloudflare Worker protected by Cloudflare Access, the goal is:
- Users authenticate with Cloudflare Access only
- The Control UI connects successfully without asking users to paste a gateway token or add `?token=...` manually

In practice, the UI loaded over HTTP, but the WebSocket handshake failed and the gateway disconnected with policy errors.

## Symptoms

1. Browser shows:
   - `disconnected (1008): Invalid or missing token. Visit https://.../?token=...`
2. Sometimes browser shows:
   - `disconnected (1008): origin not allowed (open the Control UI from the gateway host or allow it in gateway.controlUi.allowedOrigins)`
3. Container logs show unauthorized handshakes like:
   - `reason=token_missing` for `client=openclaw-control-ui`
4. `/api/status` returns `running` (gateway process is up), but Control UI cannot connect.

## Root Cause Analysis

### 1. Gateway Enforces a Control UI Origin Allowlist

OpenClaw validates the browser `Origin` against `gateway.controlUi.allowedOrigins`.

Behind a Worker, the browser origin is the Worker hostname (for example `https://<worker>.workers.dev`), not `http://localhost:18789`.

**Fix:** set `gateway.controlUi.allowedOrigins` to the Worker origin derived from `WORKER_URL`.

Implementation: `start-moltbot.sh` sets:
- `config.gateway.controlUi.allowInsecureAuth = true`
- `config.gateway.controlUi.allowedOrigins = [new URL(WORKER_URL).origin]`

### 2. Control UI Auth Token Is Sent In The WebSocket `connect` Request Payload

The Control UI client does:
- `new WebSocket(settings.gatewayUrl)`
- waits for `connect.challenge`
- sends a `connect` request

Auth is carried in the `connect` payload under:
- `params.auth.token` (or password)

This means:
- Adding a `?token=` query param to the **WebSocket URL** does not authenticate the Control UI by itself
- The UI only sends an auth token if its **settings.token** is set (from localStorage or from the **page URL** `?token=...`)
- Cloudflare Access redirects can strip the **page URL** query string, so relying on users visiting `/?token=...` is fragile

**Fix:** inject `params.auth.token` server-side when the Worker sees a `connect` request frame.

Implementation: `src/index.ts` intercepts client → container frames and:
- if message is `{ type: "req", method: "connect" }`, injects `params.auth.token` from `MOLTBOT_GATEWAY_TOKEN`
- deletes `params.device` to force token-only auth (avoids device signature mismatch issues when the UI tries device identity auth)
- removes `auth.password`

Helper: `src/utils/ws.ts` (`injectGatewayTokenIntoConnectRequest()`), with tests in `src/utils/ws.test.ts`.

### 3. Sandbox WebSocket Proxying Has Its Own Constraints

Cloudflare Sandbox `wsConnect()` is sensitive to how the target URL is constructed.

For query-param-dependent flows, you should construct an explicit localhost URL:
- `http://localhost:${MOLTBOT_PORT}${pathname}${search}`

This is still worth keeping as a best-effort fallback, but it is not the primary fix for Control UI auth in modern OpenClaw versions.

### 4. Containers Persist Across Deploys (You Must Restart To Pick Up Startup Script Changes)

The Sandbox Durable Object can keep using an existing container + running gateway process even after a Worker deploy.

When changing anything baked into the container image (like `start-moltbot.sh`), you must force a restart:
- `GET /api/status?reset=<MOLTBOT_GATEWAY_TOKEN>` to destroy the container
- then poll `/api/status` until it reports `running`

## Solution Summary

1. **Origin fix (container config)**:
   - Set `gateway.controlUi.allowedOrigins` to the Worker origin from `WORKER_URL`.
2. **Auth fix (Worker WebSocket proxy)**:
   - Inject `params.auth.token` into the `connect` request frame.
   - Strip `params.device` to force token-only auth behind Cloudflare Access.
3. **Ops**:
   - Reset the container after deploys to ensure the new startup script takes effect.

## Verification

### Fast checks

- `GET /api/status` returns `{"ok":true,"status":"running"}`.

### WebSocket handshake check (recommended)

Use a WebSocket client (for example `wscat`) with a valid Cloudflare Access session cookie:
1. Connect to `wss://<worker-host>/`
2. Observe a `connect.challenge` event
3. Send a `connect` request **without any auth fields**

Expected after fix:
- The Worker injects the token into the connect request
- Gateway responds with `hello-ok` instead of closing with `1008`

## Security / Cleanup Learnings

1. **Do not log full config**: `start-moltbot.sh` should never print the full `openclaw.json` because it contains secrets.
2. **Debug endpoints must redact secrets**: `/debug/logs`, `/debug/cli`, and `/debug/processes?logs=true` should apply redaction.
3. **Rotate secrets if they were exposed**: if any logs previously included tokens/keys, rotate those credentials.

## Related

- `src/index.ts` (WebSocket proxy + connect-frame injection)
- `src/utils/ws.ts` (connect-frame mutation helper)
- `start-moltbot.sh` (allowedOrigins + allowInsecureAuth)
- `src/routes/public.ts` (`/api/status` reset and startup gating)
- `docs/solutions/integration-issues/sandbox-wsconnect-query-param-forwarding.md` (query param forwarding notes)

