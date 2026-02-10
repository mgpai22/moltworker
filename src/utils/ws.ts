/**
 * WebSocket helpers for proxying the OpenClaw gateway.
 *
 * The OpenClaw Control UI sends gateway auth in the `connect` request payload
 * (`params.auth.token`), not as a WebSocket URL query parameter.
 *
 * When running behind Cloudflare Access, we want the browser to connect without
 * requiring the user to paste a token into the UI. The Worker injects the
 * gateway token into the `connect` frame server-side.
 */

type JsonObject = Record<string, unknown>;

function isObject(value: unknown): value is JsonObject {
  return !!value && typeof value === 'object' && !Array.isArray(value);
}

/**
 * If `raw` is a gateway `connect` request, ensure it contains `params.auth.token`
 * set to the provided gateway token. Also strips `params.device` to force
 * token-only auth when `allowInsecureAuth` is enabled on the gateway; otherwise
 * device signatures may not match once we inject a token.
 */
export function injectGatewayTokenIntoConnectRequest(
  raw: string,
  gatewayToken: string | undefined,
): string {
  const token = gatewayToken?.trim();
  if (!token) return raw;

  let msg: unknown;
  try {
    msg = JSON.parse(raw);
  } catch {
    return raw;
  }

  if (!isObject(msg)) return raw;
  if (msg.type !== 'req' || msg.method !== 'connect') return raw;

  const params = msg.params;
  if (!isObject(params)) return raw;

  // Ensure auth object exists and contains token.
  const auth = isObject(params.auth) ? { ...params.auth } : {};
  auth.token = token;
  // Prefer token auth over password auth.
  delete auth.password;

  // Force token-only handshake; avoids device signature mismatches.
  const nextParams: JsonObject = { ...params, auth };
  delete nextParams.device;

  const nextMsg: JsonObject = { ...msg, params: nextParams };
  return JSON.stringify(nextMsg);
}
