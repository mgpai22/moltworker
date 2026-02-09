import type { Context, Next } from 'hono';
import type { AppEnv, MoltbotEnv } from '../types';
import { verifyAccessJWT } from './jwt';

/**
 * Options for creating an access middleware
 */
export interface AccessMiddlewareOptions {
  /** Response type: 'json' for API routes, 'html' for UI routes */
  type: 'json' | 'html';
  /** Whether to redirect to login when JWT is missing (only for 'html' type) */
  redirectOnMissing?: boolean;
}

/**
 * Check if running in development mode (skips CF Access auth + device pairing)
 */
export function isDevMode(env: MoltbotEnv): boolean {
  return env.DEV_MODE === 'true';
}

/**
 * Check if running in E2E test mode (skips CF Access auth but keeps device pairing)
 */
export function isE2ETestMode(env: MoltbotEnv): boolean {
  return env.E2E_TEST_MODE === 'true';
}

/**
 * Extract JWT from request headers or cookies
 */
export function extractJWT(c: Context<AppEnv>): string | null {
  const jwtHeader = c.req.header('CF-Access-JWT-Assertion');
  const jwtCookie = c.req.raw.headers
    .get('Cookie')
    ?.split(';')
    .find((cookie) => cookie.trim().startsWith('CF_Authorization='))
    ?.split('=')[1];

  return jwtHeader || jwtCookie || null;
}

/**
 * Extract an admin API token from request headers.
 *
 * Supported headers:
 * - Authorization: Bearer <token>
 * - X-Admin-Token: <token>
 */
function extractAdminToken(c: Context<AppEnv>): string | null {
  const direct = c.req.header('X-Admin-Token')?.trim();
  if (direct) return direct;

  const auth = c.req.header('Authorization')?.trim();
  if (!auth) return null;

  const match = auth.match(/^Bearer\s+(.+)$/i);
  return match?.[1]?.trim() || null;
}

/**
 * Create a Cloudflare Access authentication middleware
 *
 * @param options - Middleware options
 * @returns Hono middleware function
 */
export function createAccessMiddleware(options: AccessMiddlewareOptions) {
  const { type, redirectOnMissing = false } = options;

  return async (c: Context<AppEnv>, next: Next) => {
    // Skip auth in dev mode or E2E test mode
    if (isDevMode(c.env) || isE2ETestMode(c.env)) {
      c.set('accessUser', { email: 'dev@localhost', name: 'Dev User' });
      return next();
    }

    // Optional bearer-token auth for programmatic admin access.
    // This is evaluated before Cloudflare Access config/JWT checks so automation
    // can call admin APIs without a browser session cookie.
    const configuredAdminToken = c.env.ADMIN_API_TOKEN;
    if (configuredAdminToken) {
      const providedToken = extractAdminToken(c);
      if (providedToken && providedToken === configuredAdminToken) {
        c.set('accessUser', { email: 'admin-token@localhost', name: 'Admin Token' });
        return next();
      }

      // If a token was provided but doesn't match, only hard-fail when there is
      // no Cloudflare Access JWT present. This avoids breaking valid Access
      // requests that happen to include an unrelated Authorization header.
      if (providedToken && !extractJWT(c)) {
        if (type === 'json') {
          return c.json({ error: 'Unauthorized', hint: 'Invalid ADMIN_API_TOKEN' }, 401);
        }
        return c.html(`
          <html>
            <body>
              <h1>Unauthorized</h1>
              <p>Invalid admin token.</p>
            </body>
          </html>
        `, 401);
      }
    }

    const teamDomain = c.env.CF_ACCESS_TEAM_DOMAIN;
    const expectedAud = c.env.CF_ACCESS_AUD;

    // Check if CF Access is configured
    if (!teamDomain || !expectedAud) {
      if (type === 'json') {
        return c.json(
          {
            error: 'Cloudflare Access not configured',
            hint: 'Set CF_ACCESS_TEAM_DOMAIN and CF_ACCESS_AUD environment variables',
          },
          500,
        );
      } else {
        return c.html(
          `
          <html>
            <body>
              <h1>Admin UI Not Configured</h1>
              <p>Set CF_ACCESS_TEAM_DOMAIN and CF_ACCESS_AUD environment variables.</p>
            </body>
          </html>
        `,
          500,
        );
      }
    }

    // Get JWT
    const jwt = extractJWT(c);

    if (!jwt) {
      if (type === 'html' && redirectOnMissing) {
        return c.redirect(`https://${teamDomain}`, 302);
      }

      if (type === 'json') {
        return c.json(
          {
            error: 'Unauthorized',
            hint: 'Missing Cloudflare Access JWT. Ensure this route is protected by Cloudflare Access.',
          },
          401,
        );
      } else {
        return c.html(
          `
          <html>
            <body>
              <h1>Unauthorized</h1>
              <p>Missing Cloudflare Access token.</p>
              <a href="https://${teamDomain}">Login</a>
            </body>
          </html>
        `,
          401,
        );
      }
    }

    // Verify JWT
    try {
      const payload = await verifyAccessJWT(jwt, teamDomain, expectedAud);
      c.set('accessUser', { email: payload.email, name: payload.name });
      await next();
    } catch (err) {
      console.error('Access JWT verification failed:', err);

      if (type === 'json') {
        return c.json(
          {
            error: 'Unauthorized',
            details: err instanceof Error ? err.message : 'JWT verification failed',
          },
          401,
        );
      } else {
        return c.html(
          `
          <html>
            <body>
              <h1>Unauthorized</h1>
              <p>Your Cloudflare Access session is invalid or expired.</p>
              <a href="https://${teamDomain}">Login again</a>
            </body>
          </html>
        `,
          401,
        );
      }
    }
  };
}
