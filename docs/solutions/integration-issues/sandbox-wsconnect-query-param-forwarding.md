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

Note: This document is specifically about **query parameter forwarding** through `sandbox.wsConnect()`.
Modern OpenClaw Control UI authentication is primarily driven by the **WebSocket `connect` frame**
(`params.auth.token`). See:
- `docs/solutions/integration-issues/control-ui-ws-auth-connect-frame-token-injection.md`

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

## Update (2026-02-10): Control UI Token Is In The `connect` Frame

Newer OpenClaw Control UI builds send gateway auth inside the WebSocket `connect` request payload
(`params.auth.token`), not by appending `?token=` to the WebSocket URL. The `?token=` query param
still matters for *browser UX* (the UI reads `location.search` and stores the token), but a Worker
proxy that wants the UI to "just work" should inject `params.auth.token` server-side when it sees a
`connect` request.

This means:
- Fixing `wsConnect()` query param forwarding is still useful for other query-param-dependent flows.
- But it is not sufficient by itself to solve Control UI auth in modern OpenClaw versions.

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

1. **Protocol-level token injection into the wrong field** — Adding `token` as an unexpected property
   (e.g., at the top-level, or as `params.token`) is rejected by the gateway. If you need the Control UI
   to authenticate without user input, the correct place is `params.auth.token` inside the `connect` request
   payload (see the Control UI auth solution doc).

2. **Passing original request URL** — `sandbox.wsConnect(request)` strips query params silently.

## Prevention

1. **Never assume query parameter forwarding** with `sandbox.wsConnect()` — always construct explicit localhost URLs
2. **Test auth flow end-to-end** after any WebSocket proxy changes
3. **Use localhost URLs** for container communication — more reliable with Sandbox APIs
4. **Log URLs at both Worker and container level** to verify params flow through

## Related

- `src/index.ts` — WebSocket proxy implementation
- `docs/solutions/integration-issues/control-ui-ws-auth-connect-frame-token-injection.md` — Control UI auth behind Worker
- `src/config.ts` — `MOLTBOT_PORT = 18789`
- `src/gateway/env.ts` — `MOLTBOT_GATEWAY_TOKEN` → `OPENCLAW_GATEWAY_TOKEN` mapping
- `docs/solutions/integration-issues/upstream-merge-cascading-deploy-failures.md` — Related WebSocket failures
