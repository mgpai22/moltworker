import { Hono } from 'hono';
import { describe, expect, it, vi } from 'vitest';

import type { Sandbox } from '@cloudflare/sandbox';
import type { AppEnv, MoltbotEnv } from '../types';
import { publicRoutes } from './public';

function createTestApp(options: {
  env: Partial<MoltbotEnv>;
  sandbox: Record<string, unknown>;
}): { app: Hono<AppEnv>; env: MoltbotEnv } {
  const app = new Hono<AppEnv>();

  // Minimal env bindings for Hono/Worker-style fetch().
  const env = {
    Sandbox: null as unknown as DurableObjectNamespace<Sandbox>,
    ASSETS: { fetch: vi.fn() } as unknown as Fetcher,
    MOLTBOT_BUCKET: null as unknown as R2Bucket,
    ...options.env,
  } satisfies MoltbotEnv;

  app.use('*', async (c, next) => {
    c.set('sandbox', options.sandbox as any);
    await next();
  });
  app.route('/', publicRoutes);

  return { app, env };
}

describe('GET /api/status', () => {
  it('refuses to start the gateway when MOLTBOT_GATEWAY_TOKEN is missing (non-dev mode)', async () => {
    const sandbox = {
      containerFetch: vi.fn().mockRejectedValue(new Error('connection refused')),
      startProcess: vi.fn(),
      destroy: vi.fn(),
    };

    const { app, env } = createTestApp({
      env: {
        DEV_MODE: 'false',
        MOLTBOT_GATEWAY_TOKEN: undefined,
      },
      sandbox,
    });

    const res1 = await app.fetch(new Request('http://example.com/api/status'), env, {} as any);
    expect(res1.status).toBe(503);
    const body1 = (await res1.json()) as any;
    expect(body1).toMatchObject({ ok: false, status: 'error' });
    expect(body1.missing).toEqual(expect.arrayContaining(['MOLTBOT_GATEWAY_TOKEN']));

    // Ensure we didn't accidentally trip the cooldown logic; the error should be stable.
    const res2 = await app.fetch(new Request('http://example.com/api/status'), env, {} as any);
    expect(res2.status).toBe(503);
    const body2 = (await res2.json()) as any;
    expect(body2).toMatchObject({ ok: false, status: 'error' });
    expect(body2.missing).toEqual(expect.arrayContaining(['MOLTBOT_GATEWAY_TOKEN']));

    expect(sandbox.startProcess).not.toHaveBeenCalled();
  });

  it('refuses to start the gateway when WORKER_URL is missing (non-dev mode)', async () => {
    const sandbox = {
      containerFetch: vi.fn().mockRejectedValue(new Error('connection refused')),
      startProcess: vi.fn(),
      destroy: vi.fn(),
    };

    const { app, env } = createTestApp({
      env: {
        DEV_MODE: 'false',
        MOLTBOT_GATEWAY_TOKEN: 'token',
        WORKER_URL: undefined,
      },
      sandbox,
    });

    const res = await app.fetch(new Request('http://example.com/api/status'), env, {} as any);
    expect(res.status).toBe(503);
    await expect(res.json()).resolves.toMatchObject({
      ok: false,
      status: 'error',
      missing: ['WORKER_URL'],
    });

    expect(sandbox.startProcess).not.toHaveBeenCalled();
  });
});
