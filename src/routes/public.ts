import { Hono } from 'hono';
import type { AppEnv } from '../types';
import { MOLTBOT_PORT } from '../config';
import { buildEnvVars } from '../gateway/env';
import { mountR2Storage } from '../gateway/r2';

/**
 * Public routes - NO Cloudflare Access authentication required
 * 
 * These routes are mounted BEFORE the auth middleware is applied.
 * Includes: health checks, static assets, and public API endpoints.
 */
const publicRoutes = new Hono<AppEnv>();

// GET /sandbox-health - Health check endpoint
publicRoutes.get('/sandbox-health', (c) => {
  return c.json({
    status: 'ok',
    service: 'moltbot-sandbox',
    gateway_port: MOLTBOT_PORT,
  });
});

// GET /logo.png - Serve logo from ASSETS binding
publicRoutes.get('/logo.png', (c) => {
  return c.env.ASSETS.fetch(c.req.raw);
});

// GET /logo-small.png - Serve small logo from ASSETS binding
publicRoutes.get('/logo-small.png', (c) => {
  return c.env.ASSETS.fetch(c.req.raw);
});

// GET /api/status - Public health check for gateway status (no auth required)
// Polled by the loading page every 10s. Must be FAST and LIGHTWEIGHT.
//
// Bypasses process tracking (which can become inconsistent after rapid deploys)
// and checks the gateway port directly via containerFetch.
//
// Track last start time to avoid spawning multiple gateway processes.
// NOTE: This resets on DO restarts (in-memory), so we use a generous cooldown
// to minimize the window where multiple starts can happen during rapid polls.
let lastGatewayStartTime = 0;
const GATEWAY_START_COOLDOWN_MS = 90_000; // 90s — gateway needs ~30-60s to start

publicRoutes.get('/api/status', async (c) => {
  const sandbox = c.get('sandbox');

  // Container reset mechanism: ?reset=<MOLTBOT_GATEWAY_TOKEN>
  // This destroys the container to force a fresh start with the latest image
  const resetToken = c.req.query('reset');
  if (resetToken) {
    if (resetToken === c.env.MOLTBOT_GATEWAY_TOKEN) {
      console.log('[status] Container reset requested with valid token');
      try {
        await sandbox.destroy();
        lastGatewayStartTime = 0; // Reset cooldown
        return c.json({ ok: true, status: 'reset', message: 'Container destroyed. Next request will create a fresh container.' });
      } catch (err) {
        console.error('[status] Failed to destroy container:', err);
        return c.json({ ok: false, status: 'error', error: 'Failed to reset container' }, 500);
      }
    } else {
      console.log('[status] Container reset rejected - invalid token');
      return c.json({ ok: false, status: 'error', error: 'Invalid reset token' }, 401);
    }
  }

  try {
    // Check if gateway port is responding by fetching directly (3s timeout).
    try {
      const healthReq = new Request('http://localhost/health');
      const timeout = new Promise<never>((_, reject) =>
        setTimeout(() => reject(new Error('timeout')), 3000)
      );
      const resp = await Promise.race([
        sandbox.containerFetch(healthReq, MOLTBOT_PORT),
        timeout,
      ]);
      if (resp.status < 500) {
        console.log('[status] Port up! status:', resp.status);
        return c.json({ ok: true, status: 'running' });
      }
      console.log('[status] Port responded with error:', resp.status);
    } catch {
      // Port not responding
    }

    const now = Date.now();
    const cooldownRemaining = GATEWAY_START_COOLDOWN_MS - (now - lastGatewayStartTime);
    if (cooldownRemaining > 0) {
      console.log('[status] Cooldown active, remaining:', Math.round(cooldownRemaining / 1000), 's');
      return c.json({ ok: false, status: 'starting' });
    }

    console.log('[status] Gateway not responding, starting gateway process');
    lastGatewayStartTime = now;

    try {
      // Mount R2 storage first - the startup script waits for it
      await mountR2Storage(sandbox, c.env);

      const envVars = buildEnvVars(c.env);
      const proc = await sandbox.startProcess('/usr/local/bin/start-moltbot.sh', {
        env: Object.keys(envVars).length > 0 ? envVars : undefined,
      });
      console.log('[status] Gateway process started:', proc.id);
    } catch (startErr) {
      console.error('[status] Failed to start gateway:', startErr);
      lastGatewayStartTime = 0; // Reset cooldown on failure
    }
    return c.json({ ok: false, status: 'starting' });
  } catch (err) {
    return c.json({ ok: false, status: 'error', error: err instanceof Error ? err.message : 'Unknown error' });
  }
});

// GET /_admin/assets/* - Admin UI static assets (CSS, JS need to load for login redirect)
// Assets are built to dist/client with base "/_admin/"
publicRoutes.get('/_admin/assets/*', async (c) => {
  const url = new URL(c.req.url);
  // Rewrite /_admin/assets/* to /assets/* for the ASSETS binding
  const assetPath = url.pathname.replace('/_admin/assets/', '/assets/');
  const assetUrl = new URL(assetPath, url.origin);
  return c.env.ASSETS.fetch(new Request(assetUrl.toString(), c.req.raw));
});

export { publicRoutes };
