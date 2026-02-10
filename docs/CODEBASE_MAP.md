# Codebase Map

> Generated: 2026-02-10T03:42:10Z

## Overview

**Moltworker** is a Cloudflare Worker that runs the Moltbot personal AI assistant inside a Cloudflare Sandbox container. It proxies HTTP/WebSocket requests to the OpenClaw gateway running in the container, manages the gateway lifecycle, handles authentication via Cloudflare Access, and persists data to R2 storage.

**Tech stack:** TypeScript, Hono (web framework), Cloudflare Workers, Cloudflare Sandbox (Durable Objects + containers), R2 object storage, Vite, Vitest, React (admin UI).

## Architecture

```
                    Internet
                       │
                       ▼
           ┌───────────────────────┐
           │  Cloudflare Access    │  ← JWT auth (CF_ACCESS_TEAM_DOMAIN)
           └───────────┬───────────┘
                       │
                       ▼
┌──────────────────────────────────────────────────┐
│              Cloudflare Worker (src/index.ts)     │
│                                                   │
│  Hono app with middleware chain:                  │
│  1. Request logging                               │
│  2. Sandbox initialization (Durable Object)       │
│  3. Public routes (no auth)                       │
│  4. Env validation                                │
│  5. CF Access JWT verification                    │
│  6. Protected routes (API, Admin UI, Debug)       │
│  7. Catch-all proxy → container                   │
│                                                   │
│  WebSocket: intercepts messages for error         │
│  transformation, injects gateway token into       │
│  the Control UI `connect` frame                   │
│                                                   │
│  Cron: syncs container config → R2 every 5min     │
└───────────────┬──────────────────────────────────┘
                │  sandbox.containerFetch / wsConnect
                ▼
┌──────────────────────────────────────────────────┐
│         Cloudflare Sandbox Container              │
│         (Dockerfile → cloudflare/sandbox:0.7.0)   │
│                                                   │
│  start-moltbot.sh:                                │
│    1. Restore R2 backup → /root/.openclaw/        │
│    2. Generate openclaw.json from env vars         │
│    3. Write .env file for skills                   │
│    4. Launch: openclaw gateway --bind 0.0.0.0      │
│                                                   │
│  Port 18789: OpenClaw Gateway                     │
│    ├── Web UI (Control Dashboard + WebChat)        │
│    ├── WebSocket RPC protocol                      │
│    └── Agent runtime (Claude, OpenAI, etc.)        │
│                                                   │
│  Skills at /root/clawd/skills/                     │
│  Workspace at /root/.openclaw/workspace/           │
│                                                   │
│  Installed tools: Node.js 22, openclaw, gh,        │
│  agent-browser, bitwarden CLI, summarize,          │
│  goplaces, wacli, imgbb, gemini CLI, uv, Go       │
└──────────────────────────────────────────────────┘
                │
                ▼
┌──────────────────────────────────────────────────┐
│  R2 Bucket (moltbot-data)                         │
│  Mounted at /data/moltbot via s3fs                 │
│                                                   │
│  /openclaw/   ← config, sessions, conversations    │
│  /skills/     ← skill state                        │
│  .last-sync   ← timestamp of last cron sync        │
└──────────────────────────────────────────────────┘
```

## File Map

### Root

| File | Purpose |
|------|---------|
| `Dockerfile` | Container image: sandbox base + Node 22 + CLI tools + skills |
| `start-moltbot.sh` | Container startup: restores R2 backup, generates config from env vars, launches gateway (~756 lines) |
| `start-openclaw.sh` | Legacy upstream startup script (unused in this fork) |
| `wrangler.jsonc` | Worker config: container (standard-4), R2 bucket, cron, browser binding, assets |
| `package.json` | Dependencies: hono, jose, @cloudflare/puppeteer, react |
| `vite.config.ts` | Vite build config for worker + admin UI |
| `vitest.config.ts` | Test configuration |
| `tsconfig.json` | TypeScript config |
| `AGENTS.md` | AI agent guidelines, architecture, troubleshooting |
| `README.md` | User-facing documentation |
| `openclaw/openclaw.json` | Default OpenClaw config template |

### `src/` - Worker Source

| File | Purpose | Key Exports |
|------|---------|-------------|
| `index.ts` | Main Hono app, middleware chain, WebSocket proxy, cron handler | `default { fetch, scheduled }`, `Sandbox` |
| `types.ts` | TypeScript types | `MoltbotEnv`, `AppEnv`, `AccessUser`, `JWTPayload` |
| `config.ts` | Constants | `MOLTBOT_PORT` (18789), `STARTUP_TIMEOUT_MS` (180s), `R2_MOUNT_PATH`, `getR2BucketName()` |
| `env.d.ts` | HTML/PNG import type declarations | |
| `assets.d.ts` | Asset type declarations | |
| `test-utils.ts` | Shared test helpers | |

### `src/auth/` - Authentication

| File | Purpose |
|------|---------|
| `index.ts` | Barrel exports |
| `jwt.ts` | `verifyAccessJWT()` - Verifies CF Access JWTs using jose + JWKS |
| `middleware.ts` | `createAccessMiddleware()` - Hono middleware for CF Access auth; supports dev/E2E bypass, admin token auth, HTML/JSON responses |
| `jwt.test.ts` | JWT verification tests |
| `middleware.test.ts` | Auth middleware behavior tests |

### `src/gateway/` - Container Lifecycle

| File | Purpose |
|------|---------|
| `index.ts` | Barrel exports |
| `process.ts` | `findExistingMoltbotProcess()` - finds running gateway; `ensureMoltbotGateway()` - mounts R2, finds/starts gateway, waits for port |
| `env.ts` | `buildEnvVars()` - maps Worker env → container env vars (AI keys, gateway token, channel tokens, skill API keys) |
| `r2.ts` | `mountR2Storage()` - mounts R2 bucket via s3fs at /data/moltbot |
| `sync.ts` | `syncToR2()` - rsyncs /root/.openclaw/ and /root/clawd/skills/ to R2 with safety checks |
| `utils.ts` | `waitForProcess()` - polls process status with timeout |
| `env.test.ts` | Env var building tests |
| `process.test.ts` | Process finding logic tests |
| `r2.test.ts` | R2 mounting tests |
| `sync.test.ts` | Sync logic tests |

### `src/routes/` - HTTP Routes

| File | Routes | Auth | Purpose |
|------|--------|------|---------|
| `index.ts` | | | Barrel exports |
| `public.ts` | `GET /sandbox-health`, `GET /logo.png`, `GET /logo-small.png`, `GET /api/status`, `GET /_admin/assets/*` | None | Health check, static assets, gateway status polling with cooldown, container reset (`?reset=<token>`) |
| `api.ts` | `GET /api/admin/devices`, `POST /api/admin/devices/:id/approve`, `POST /api/admin/devices/approve-all`, `GET /api/admin/storage`, `POST /api/admin/storage/sync`, `POST /api/admin/gateway/restart` | CF Access | Device management, R2 storage status, gateway restart |
| `admin-ui.ts` | `GET /_admin/*` | CF Access | SPA serving via ASSETS binding |
| `debug.ts` | `GET /debug/version`, `GET /debug/processes`, `GET /debug/gateway-api`, `GET /debug/cli`, `GET /debug/logs`, `GET /debug/ws-test`, `GET /debug/env`, `GET /debug/container-config`, `POST /debug/reset-container` | CF Access + DEBUG_ROUTES=true | Container inspection, WebSocket debug tool, environment check |
| `cdp.ts` | `GET /cdp` (WS), `GET /cdp/json/version`, `GET /cdp/json/list`, `GET /cdp/json` | CDP_SECRET query param | Chrome DevTools Protocol shim over Cloudflare Browser Rendering binding; supports Browser, Target, Page, Runtime, DOM, Input, Network, Emulation, Fetch domains |

### `src/utils/`

| File | Purpose |
|------|---------|
| `logging.ts` | `redactSensitiveParams()` - redacts tokens/keys/passwords from URL params for safe logging |

### `src/client/` - Admin UI (React)

| File | Purpose |
|------|---------|
| `api.ts` | API client for admin endpoints |

### `skills/` - OpenClaw Skills (12 skills)

Each skill has `SKILL.md` (docs with YAML frontmatter) and `scripts/` (executable commands).

| Skill | Description | Key Env Vars |
|-------|-------------|--------------|
| `agent-browser` | Headless browser automation (Playwright-based) | None (uses agent-browser CLI) |
| `bird` | X/Twitter client (read tweets, search, bookmarks, trending) | `AUTH_TOKEN`, `CT0` |
| `bitwarden` | Password manager CLI (vault CRUD, TOTP, send) | `BW_EMAIL`, `BW_PASSWORD` |
| `cloudflare-browser` | Browser via CDP shim to Worker's Browser Rendering binding | `CDP_SECRET`, `WORKER_URL` |
| `gemini` | Google Gemini AI prompts | `GEMINI_API_KEY` |
| `gemini-stt` | Speech-to-text via Gemini | `GEMINI_API_KEY` or `GOOGLE_API_KEY` |
| `github` | GitHub CLI wrapper (repos, PRs, issues, gists, releases, actions) | `GH_TOKEN` |
| `imgbb` | Image upload to ImgBB | `IMGBB_API_KEY` |
| `nia` | Code/docs indexing and semantic search | `NIA_API_KEY` |
| `obsidian` | Obsidian vault management via REST API | `OBSIDIAN_API_URL`, `OBSIDIAN_API_KEY` |
| `summarize` | URL/YouTube/podcast/PDF/media summarization | `GEMINI_API_KEY` or `OPENROUTER_API_KEY` |
| `whatsapp` | WhatsApp messaging via wacli (Go binary) | None (uses QR auth) |

### `docs/`

| File | Purpose |
|------|---------|
| `DEPLOYMENT.md` | Deployment and configuration guide |
| `SKILLS.md` | How to create and add new skills |
| `SKILL-ENV-VARS.md` | Complete environment variable reference for all skills |

### `test/`

| Path | Purpose |
|------|---------|
| `test/e2e/README.md` | E2E test documentation |

## Key Data Flows

### Request Lifecycle (HTTP)

1. Request hits Cloudflare Access (edge auth)
2. Worker middleware: log, init sandbox DO, check public routes
3. If protected: validate env vars, verify CF Access JWT
4. Catch-all: check if gateway running → show loading page or proxy
5. `ensureMoltbotGateway()`: mount R2, find/start process, wait for port 18789
6. `sandbox.containerFetch(request, MOLTBOT_PORT)` → response

### Request Lifecycle (WebSocket)

1. Same auth flow as HTTP
2. Worker constructs an explicit localhost URL for `wsConnect()` (best-effort query param preservation)
3. `sandbox.wsConnect(wsRequest, MOLTBOT_PORT)` → container WebSocket
4. Worker creates `WebSocketPair`, relays messages bidirectionally
5. Client→Container messages: if JSON `connect` request, inject `params.auth.token` (and strip `params.device`) so the UI works without user-pasted tokens
6. Container→Client messages: JSON error messages are intercepted and transformed to user-friendly text
7. Close reasons are also transformed (e.g., "gateway token missing" → "Visit https://...")

### Container Startup (`start-moltbot.sh`)

1. Wait for R2 mount (if configured)
2. Restore backup: rsync R2 → /root/.openclaw/ and /root/clawd/skills/
3. Generate `openclaw.json` from env vars via inline Node.js:
   - AI provider config (Anthropic, OpenAI, AI Gateway)
   - Channel config (Telegram, Discord, Slack) with DM policies
   - Skill env vars
   - Gateway settings (port, bind mode, token)
4. Write `.env` file with all skill API keys
5. Launch `openclaw gateway --bind 0.0.0.0 --port 18789 --allow-unconfigured`

### R2 Sync (Cron every 5min)

1. Check if gateway process is running
2. Mount R2 if not mounted
3. Verify `/root/.openclaw/openclaw.json` exists (prevent empty backup)
4. rsync `/root/.openclaw/` → R2 `/openclaw/` (excludes locks, logs, .git)
5. rsync `/root/clawd/skills/` → R2 `/skills/`
6. Write timestamp to R2 `/.last-sync`

## Environment Variable Flow

```
Wrangler Secrets (wrangler secret put)
        │
        ▼
Worker env (MoltbotEnv interface)
        │
        ├── Used directly by Worker for:
        │   - Auth (CF_ACCESS_*, ADMIN_API_TOKEN)
        │   - Env validation
        │   - WebSocket connect-frame token injection (`params.auth.token`)
        │   - CDP secret verification
        │
        └── buildEnvVars() maps to container env:
            MOLTBOT_GATEWAY_TOKEN → OPENCLAW_GATEWAY_TOKEN
            DEV_MODE → OPENCLAW_DEV_MODE
            All others passed through as-is
                    │
                    ▼
            start-moltbot.sh reads env vars
                    │
                    ├── Generates openclaw.json (AI config, channels, skills)
                    ├── Writes .env file (skill API keys)
                    └── Passes token via --token flag to openclaw gateway
```

## Dependencies

| Package | Purpose |
|---------|---------|
| `hono` | Web framework for routing and middleware |
| `jose` | JWT verification for Cloudflare Access |
| `@cloudflare/puppeteer` | Browser Rendering binding (CDP shim) |
| `@cloudflare/sandbox` | Sandbox container API (dev dependency) |
| `react`, `react-dom` | Admin UI |
| `vite`, `@cloudflare/vite-plugin` | Build tooling |
| `vitest` | Testing |
| `oxlint`, `oxfmt` | Linting and formatting |
| `wrangler` | Cloudflare Workers CLI |
