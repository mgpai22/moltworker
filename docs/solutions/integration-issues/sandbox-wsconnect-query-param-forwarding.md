---
title: Cloudflare Sandbox wsConnect Does Not Forward URL Query Parameters
category: integration-issues
component: src/index.ts
symptoms:
  - WebSocket 1008 "Invalid or missing token"
  - Container logs show URL path without query parameters
  - HTTP endpoints work but WebSocket connections fail authentication
root_cause: Cloudflare Sandbox wsConnect() strips query parameters when proxying to container
date: 2026-02-09
severity: high
---

# Cloudflare Sandbox wsConnect Does Not Forward URL Query Parameters

## Problem

After deploying the moltworker, WebSocket connections to the OpenClaw gateway failed with 1008 "Invalid or missing token", despite the gateway being healthy and HTTP requests working correctly.

## Symptoms

1. WebSocket closes immediately with code 1008
2. Container logs show `[WS] URL: /` instead of `/?token=xxx`
3. HTTP `/api/status` works fine — only WebSocket affected
4. Gateway health check passes

## Root Cause

Cloudflare Sandbox's `wsConnect()` does NOT forward URL query parameters from the incoming request to the container. When calling:

```typescript
sandbox.wsConnect(request, MOLTBOT_PORT);
// request.url = "wss://domain.com/chat?token=xxx"
// Container receives: /chat (no ?token=xxx)
```

This differs from `containerFetch()` which does preserve query parameters.

## Solution

Construct an explicit localhost URL with all needed query parameters:

```typescript
const url = new URL(request.url);
const localUrl = new URL(
  url.pathname + url.search,
  `http://localhost:${MOLTBOT_PORT}`
);
if (!localUrl.searchParams.has('token')) {
  localUrl.searchParams.set('token', c.env.MOLTBOT_GATEWAY_TOKEN);
}
const wsRequest = new Request(localUrl.toString(), request);
const containerResponse = await sandbox.wsConnect(wsRequest, MOLTBOT_PORT);
```

## What Didn't Work

1. **Protocol-level token injection** — Intercepting WebSocket `connect` message and adding `token` field. Gateway rejected with "unexpected property 'token'" — it expects token in URL query, not message body.

2. **Passing original request URL** — `sandbox.wsConnect(request)` strips query params silently.

## Prevention

1. **Never assume query parameter forwarding** with `sandbox.wsConnect()` — always construct explicit localhost URLs
2. **Test auth flow end-to-end** after any WebSocket proxy changes
3. **Use localhost URLs** for container communication — more reliable with Sandbox APIs
4. **Log URLs at both Worker and container level** to verify params flow through

## Related

- `src/index.ts` — WebSocket proxy implementation
- `src/config.ts` — `MOLTBOT_PORT = 18789`
- `src/gateway/env.ts` — `MOLTBOT_GATEWAY_TOKEN` → `OPENCLAW_GATEWAY_TOKEN` mapping
- `docs/solutions/integration-issues/upstream-merge-cascading-deploy-failures.md` — Related WebSocket failures
