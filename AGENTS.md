# Agent Instructions

Guidelines for AI agents working on this codebase.

## Project Overview

This is a Cloudflare Worker that runs [Moltbot](https://molt.bot/) in a Cloudflare Sandbox container. It provides:
- Proxying to the Moltbot gateway (web UI + WebSocket)
- Admin UI at `/_admin/` for device management
- API endpoints at `/api/*` for device pairing
- Debug endpoints at `/debug/*` for troubleshooting

**Note:** The CLI tool was renamed from `clawdbot` to `openclaw`. CLI commands use `openclaw`, but some internal config paths may still use the old name (e.g., `~/.clawdbot/`).

## Project Structure

```
src/
├── index.ts          # Main Hono app, route mounting
├── types.ts          # TypeScript type definitions
├── config.ts         # Constants (ports, timeouts, paths)
├── auth/             # Cloudflare Access authentication
│   ├── jwt.ts        # JWT verification
│   ├── jwks.ts       # JWKS fetching and caching
│   └── middleware.ts # Hono middleware for auth
├── gateway/          # Moltbot gateway management
│   ├── process.ts    # Process lifecycle (find, start)
│   ├── env.ts        # Environment variable building
│   ├── r2.ts         # R2 bucket mounting
│   ├── sync.ts       # R2 backup sync logic
│   └── utils.ts      # Shared utilities (waitForProcess)
├── routes/           # API route handlers
│   ├── api.ts        # /api/* endpoints (devices, gateway)
│   ├── admin.ts      # /_admin/* static file serving
│   └── debug.ts      # /debug/* endpoints
└── client/           # React admin UI (Vite)
    ├── App.tsx
    ├── api.ts        # API client
    └── pages/
```

## Key Patterns

### Environment Variables

- `DEV_MODE` - Skips CF Access auth AND bypasses device pairing (maps to `CLAWDBOT_DEV_MODE` for container)
- `DEBUG_ROUTES` - Enables `/debug/*` routes (disabled by default)
- See `src/types.ts` for full `MoltbotEnv` interface

### CLI Commands

When calling the openclaw CLI from the worker, always include `--url ws://localhost:18789`:
```typescript
sandbox.startProcess('openclaw devices list --json --url ws://localhost:18789')
```

CLI commands take 10-15 seconds due to WebSocket connection overhead. Use `waitForProcess()` helper in `src/routes/api.ts`.

### Success Detection

The CLI outputs "Approved" (capital A). Use case-insensitive checks:
```typescript
stdout.toLowerCase().includes('approved')
```

## Commands

```bash
npm test              # Run tests (vitest)
npm run test:watch    # Run tests in watch mode
npm run build         # Build worker + client
npm run deploy        # Build and deploy to Cloudflare
npm run dev           # Vite dev server
npm run start         # wrangler dev (local worker)
npm run typecheck     # TypeScript check
```

## Testing

Tests use Vitest. Test files are colocated with source files (`*.test.ts`).

Current test coverage:
- `auth/jwt.test.ts` - JWT decoding and validation
- `auth/jwks.test.ts` - JWKS fetching and caching
- `auth/middleware.test.ts` - Auth middleware behavior
- `gateway/env.test.ts` - Environment variable building
- `gateway/process.test.ts` - Process finding logic
- `gateway/r2.test.ts` - R2 mounting logic

When adding new functionality, add corresponding tests.

## Code Style

- Use TypeScript strict mode
- Prefer explicit types over inference for function signatures
- Keep route handlers thin - extract logic to separate modules
- Use Hono's context methods (`c.json()`, `c.html()`) for responses

## Documentation

**Always check `docs/` for detailed guides:**

| File | Description |
|------|-------------|
| `docs/SKILLS.md` | How to create and add new skills |
| `docs/SKILL-ENV-VARS.md` | Environment variables for all skills |
| `docs/DEPLOYMENT.md` | Deployment and configuration guide |

**Other docs:**
- `README.md` - User-facing documentation (setup, configuration, usage)
- `AGENTS.md` - This file, for AI agents
- `skills/<name>/SKILL.md` - Documentation for each skill

Development documentation goes in AGENTS.md, not README.md.

## Skills

Skills are in `skills/` directory. Each skill has a `SKILL.md` with full documentation.

**Available skills:** agent-browser, bird (Twitter), bitwarden, cloudflare-browser, github, imgbb, nia, obsidian, summarize, whatsapp

**Adding a new skill:** See `docs/SKILLS.md` for the complete guide.

**Skill API keys:** See `docs/SKILL-ENV-VARS.md` for all environment variables.

---

## Architecture

```
Browser
   │
   ▼
┌─────────────────────────────────────┐
│     Cloudflare Worker (index.ts)    │
│  - Starts Moltbot in sandbox        │
│  - Proxies HTTP/WebSocket requests  │
│  - Passes secrets as env vars       │
└──────────────┬──────────────────────┘
               │
               ▼
┌─────────────────────────────────────┐
│     Cloudflare Sandbox Container    │
│  ┌───────────────────────────────┐  │
│  │     Moltbot Gateway           │  │
│  │  - Control UI on port 18789   │  │
│  │  - WebSocket RPC protocol     │  │
│  │  - Agent runtime              │  │
│  └───────────────────────────────┘  │
└─────────────────────────────────────┘
```

### Key Files

| File | Purpose |
|------|---------|
| `src/index.ts` | Worker that manages sandbox lifecycle and proxies requests |
| `Dockerfile` | Container image based on `cloudflare/sandbox` with Node 22 + Moltbot |
| `start-moltbot.sh` | Startup script that configures moltbot from env vars and launches gateway |
| `moltbot.json.template` | Default Moltbot configuration template |
| `wrangler.jsonc` | Cloudflare Worker + Container configuration |

## Local Development

```bash
npm install
cp .dev.vars.example .dev.vars
# Edit .dev.vars with your ANTHROPIC_API_KEY
npm run start
```

### Environment Variables

For local development, create `.dev.vars`:

```bash
ANTHROPIC_API_KEY=sk-ant-...
DEV_MODE=true           # Skips CF Access auth + device pairing
DEBUG_ROUTES=true       # Enables /debug/* routes
```

### WebSocket Limitations

Local development with `wrangler dev` has issues proxying WebSocket connections through the sandbox. HTTP requests work but WebSocket connections may fail. Deploy to Cloudflare for full functionality.

## Docker Image Caching

The Dockerfile includes a cache bust comment. When changing `moltbot.json.template` or `start-moltbot.sh`, bump the version:

```dockerfile
# Build cache bust: 2026-01-26-v10
```

## Gateway Configuration

Moltbot configuration is built at container startup:

1. `moltbot.json.template` is copied to `~/.clawdbot/clawdbot.json` (internal path unchanged)
2. `start-moltbot.sh` updates the config with values from environment variables
3. Gateway starts with `--allow-unconfigured` flag (skips onboarding wizard)

### Container Environment Variables

These are the env vars passed TO the container (internal names):

| Variable | Config Path | Notes |
|----------|-------------|-------|
| `ANTHROPIC_API_KEY` | (env var) | OpenClaw reads directly from env |
| `ANTHROPIC_OAUTH_TOKEN` | (env var) | Alternative to API key (OAuth flow) |
| `OPENCLAW_GATEWAY_TOKEN` | `--token` flag | Mapped from `MOLTBOT_GATEWAY_TOKEN` |
| `OPENCLAW_DEV_MODE` | `controlUi.allowInsecureAuth` | Mapped from `DEV_MODE` |
| `TELEGRAM_BOT_TOKEN` | `channels.telegram.botToken` | |
| `DISCORD_BOT_TOKEN` | `channels.discord.token` | |
| `SLACK_BOT_TOKEN` | `channels.slack.botToken` | |
| `SLACK_APP_TOKEN` | `channels.slack.appToken` | |

## Moltbot Config Schema

Moltbot has strict config validation. Common gotchas:

- `agents.defaults.model` must be `{ "primary": "model/name" }` not a string
- `gateway.mode` must be `"local"` for headless operation
- No `webchat` channel - the Control UI is served automatically
- `gateway.bind` is not a config option - use `--bind` CLI flag

See [Moltbot docs](https://docs.molt.bot/gateway/configuration) for full schema.

## Common Tasks

### Adding a New API Endpoint

1. Add route handler in `src/routes/api.ts`
2. Add types if needed in `src/types.ts`
3. Update client API in `src/client/api.ts` if frontend needs it
4. Add tests

### Adding a New Environment Variable

1. Add to `MoltbotEnv` interface in `src/types.ts`
2. If passed to container, add to `buildEnvVars()` in `src/gateway/env.ts`
3. Update `.dev.vars.example`
4. Document in README.md secrets table

### Debugging

```bash
# View live logs
npx wrangler tail

# Check secrets
npx wrangler secret list
```

Enable debug routes with `DEBUG_ROUTES=true` and check `/debug/processes`.

## R2 Storage Notes

R2 is mounted via s3fs at `/data/moltbot`. Important gotchas:

- **rsync compatibility**: Use `rsync -r --no-times` instead of `rsync -a`. s3fs doesn't support setting timestamps, which causes rsync to fail with "Input/output error".

- **Mount checking**: Don't rely on `sandbox.mountBucket()` error messages to detect "already mounted" state. Instead, check `mount | grep s3fs` to verify the mount status.

- **Never delete R2 data**: The mount directory `/data/moltbot` IS the R2 bucket. Running `rm -rf /data/moltbot/*` will DELETE your backup data. Always check mount status before any destructive operations.

- **Process status**: The sandbox API's `proc.status` may not update immediately after a process completes. Instead of checking `proc.status === 'completed'`, verify success by checking for expected output (e.g., timestamp file exists after sync).

## Troubleshooting

### Issue: `openclaw: command not found` (or `clawdbot: command not found`)

**Symptom:** CLI commands fail with "command not found" when called from API routes.

**Cause:** The CLI binary name changed from `clawdbot` to `openclaw`. The container image has the new binary, but the worker code is using the old name.

**Solution:**
1. Update all CLI commands in `src/routes/api.ts` from `clawdbot` to `openclaw`
2. Verify the container image has `openclaw` installed: `npx wrangler containers list` and check the image
3. Redeploy: `npm run deploy`

---

### Issue: Gateway Token Mismatch ("Invalid or missing token")

**Symptom:**
- Gateway logs show `disconnected (1008): Invalid or missing token`
- CLI commands timeout or fail with authentication errors
- Web UI shows "Invalid or missing token"

**Cause:** The `start-moltbot.sh` script generates a **random token** if `OPENCLAW_GATEWAY_TOKEN` is not set:
```bash
OPENCLAW_GATEWAY_TOKEN="${OPENCLAW_GATEWAY_TOKEN:-$(openssl rand -hex 16)}"
```

The worker passes `MOLTBOT_GATEWAY_TOKEN` to the container as `OPENCLAW_GATEWAY_TOKEN`. If the wrong secret name is used or the secret is missing, the gateway starts with a random token that nothing else knows.

**Solution:**
1. Set the correct secret name: `npx wrangler secret put MOLTBOT_GATEWAY_TOKEN`
2. Use a stable token value (save it in `.secrets.prod` for reference)
3. Full reset may be required if gateway already started with wrong token (see "Zombie Processes" below)

**Verification:**
```bash
# Check what secrets are set
npx wrangler secret list

# Should show MOLTBOT_GATEWAY_TOKEN (not OPENCLAW_GATEWAY_TOKEN)
```

---

### Issue: Anthropic API Returns HTTP 403 Forbidden

**Symptom:** Bot responds with "HTTP 403: forbidden: Request not allowed" when trying to use Claude.

**Cause:** The Anthropic OAuth token (`ANTHROPIC_OAUTH_TOKEN`) is expired or invalid.

**Solution:**
1. Get a fresh OAuth token from Anthropic (console.anthropic.com → OAuth tokens)
2. Update the secret: `npx wrangler secret put ANTHROPIC_OAUTH_TOKEN`
3. Restart the gateway (see "Restarting the Gateway" below)

**Note:** OAuth tokens have expiration dates. If the bot suddenly stops working after a period of functioning correctly, check token expiration first.

---

### Issue: Zombie Processes / Stuck Sandbox State

**Symptom:**
- Multiple `start-moltbot.sh` processes stuck in "running" state
- `/debug/processes` shows 10+ processes that never complete
- Gateway doesn't start despite correct configuration
- CLI commands hang indefinitely

**Cause:** The Cloudflare Sandbox Durable Object maintains persistent state. When gateway processes fail mid-startup, tokens change while processes are running, or the container crashes, the sandbox can get into an inconsistent state where:
- Old process references are cached but processes are dead
- Multiple startup attempts queue up
- The gateway port (18789) is already bound by a zombie process

**Solution - Full Reset:**
```bash
# 1. Get the container ID
npx wrangler containers list
# Look for the "id" field

# 2. Delete the container
npx wrangler containers delete <container-id>

# 3. Delete the worker (this clears Durable Object state)
npx wrangler delete moltbot-sandbox --force

# 4. Redeploy
npm run deploy

# 5. Re-set all secrets (they were deleted with the worker)
echo "your-gateway-token" | npx wrangler secret put MOLTBOT_GATEWAY_TOKEN
echo "your-discord-token" | npx wrangler secret put DISCORD_BOT_TOKEN
echo "your-anthropic-token" | npx wrangler secret put ANTHROPIC_OAUTH_TOKEN
echo "your-team-domain" | npx wrangler secret put CF_ACCESS_TEAM_DOMAIN
echo "your-aud" | npx wrangler secret put CF_ACCESS_AUD
echo "open" | npx wrangler secret put DISCORD_DM_POLICY
echo "true" | npx wrangler secret put DEBUG_ROUTES
```

**Prevention:**
- Always use stable, saved tokens (store in `.secrets.prod`)
- Don't change secrets while the gateway is running without restarting
- If something seems stuck, do a full reset early rather than trying to debug

---

### Issue: CF Access Protecting All Routes

**Symptom:** Even "public" routes like `/sandbox-health` or `/debug/*` return 302 redirects to CF Access login.

**Cause:** Cloudflare Access is configured at the **Cloudflare dashboard level** for the entire worker domain. The worker's internal route middleware never runs because CF Access intercepts all requests at the edge first.

**Solution:** This is expected behavior. The worker-level "public routes" are only public relative to the worker's own auth middleware, not to CF Access.

**Note:** Discord/Telegram/etc. bot functionality is NOT affected because those connections are **outbound** from the container to the messaging platform's servers - they don't go through the worker's HTTP interface.

---

### Issue: Pairing Code Not Found in Devices List

**Symptom:** User sends pairing code via Discord DM, but the code doesn't appear when calling `/api/admin/devices`.

**Cause:** Device pairing and channel pairing are **different CLI commands**:
- `openclaw devices list` - Lists device/OAuth pairing requests
- `openclaw pairing list <channel>` - Lists channel-specific pairing codes (Discord, Telegram, etc.)

**Solution:** Use the correct endpoint:
- For Discord pairing codes: `GET /api/admin/pairing/discord`
- For approving: `POST /api/admin/pairing/discord/<code>/approve`

---

### Restarting the Gateway

If you need to restart the gateway without a full reset:

**Option 1: API endpoint (requires CF Access auth)**
```bash
curl -X POST https://your-worker.workers.dev/api/admin/gateway/restart \
  -H "Cookie: CF_Authorization=<your-jwt>"
```

**Option 2: Trigger via any request**
The gateway auto-starts on first request. If it's stuck, a full reset is usually needed.

---

### Required Secrets Checklist

When deploying fresh or after a reset, these secrets must be set:

| Secret | Required | Description |
|--------|----------|-------------|
| `MOLTBOT_GATEWAY_TOKEN` | Yes | Token for CLI ↔ gateway auth |
| `DISCORD_BOT_TOKEN` | If using Discord | Discord bot token |
| `ANTHROPIC_OAUTH_TOKEN` | Yes (or API key) | Claude API authentication |
| `CF_ACCESS_TEAM_DOMAIN` | If using CF Access | e.g., `myteam.cloudflareaccess.com` |
| `CF_ACCESS_AUD` | If using CF Access | Application audience tag |
| `DISCORD_DM_POLICY` | Optional | `open` (no pairing) or `pairing` (default) |
| `DEBUG_ROUTES` | Optional | `true` to enable `/debug/*` |

**Tip:** Keep a `.secrets.prod` file (gitignored) with all production secret values for easy reference during resets.
