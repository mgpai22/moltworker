import { describe, expect, it } from 'vitest';
import { injectGatewayTokenIntoConnectRequest } from './ws';

describe('injectGatewayTokenIntoConnectRequest', () => {
  it('returns original string when token is missing', () => {
    const raw = '{"type":"req","id":"1","method":"connect","params":{}}';
    expect(injectGatewayTokenIntoConnectRequest(raw, undefined)).toBe(raw);
    expect(injectGatewayTokenIntoConnectRequest(raw, '   \n')).toBe(raw);
  });

  it('returns original string when payload is not JSON', () => {
    const raw = 'not json';
    expect(injectGatewayTokenIntoConnectRequest(raw, 'token')).toBe(raw);
  });

  it('returns original string when not a connect request', () => {
    const raw = JSON.stringify({ type: 'req', id: '1', method: 'ping', params: {} });
    expect(injectGatewayTokenIntoConnectRequest(raw, 'token')).toBe(raw);
  });

  it('injects auth.token and strips device for connect requests', () => {
    const raw = JSON.stringify({
      type: 'req',
      id: '1',
      method: 'connect',
      params: {
        minProtocol: 3,
        maxProtocol: 3,
        device: { id: 'dev', signature: 'sig' },
      },
    });

    const out = injectGatewayTokenIntoConnectRequest(raw, ' my-token \n');
    const parsed = JSON.parse(out) as any;

    expect(parsed.type).toBe('req');
    expect(parsed.method).toBe('connect');
    expect(parsed.params?.auth?.token).toBe('my-token');
    expect(parsed.params?.auth?.password).toBeUndefined();
    expect(parsed.params?.device).toBeUndefined();
  });

  it('overwrites existing auth.token with the injected one', () => {
    const raw = JSON.stringify({
      type: 'req',
      id: '1',
      method: 'connect',
      params: {
        auth: { token: 'stale', password: 'nope' },
      },
    });

    const out = injectGatewayTokenIntoConnectRequest(raw, 'correct');
    const parsed = JSON.parse(out) as any;

    expect(parsed.params.auth.token).toBe('correct');
    expect(parsed.params.auth.password).toBeUndefined();
  });
});
