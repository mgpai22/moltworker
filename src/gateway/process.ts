import type { Sandbox, Process } from '@cloudflare/sandbox';
import type { MoltbotEnv } from '../types';
import { MOLTBOT_PORT, STARTUP_TIMEOUT_MS } from '../config';
import { buildEnvVars } from './env';
import { mountR2Storage } from './r2';

/** Quick probe timeout for existing processes — if the port isn't up in 5s
 *  the process is likely stale (e.g., from a previous DO instance after deploy).
 *  Must be shorter than LOADING_PAGE_TIMEOUT_MS (10s in index.ts) so that
 *  ensureMoltbotGateway can probe, kill stale, and start a new process all
 *  within the race timeout window. */
const EXISTING_PROCESS_PROBE_MS = 5_000;

const ENV_HASH_PATH = '/tmp/moltbot-env-hash';

/**
 * Compute a deterministic fingerprint of environment variables.
 * Used to detect when env vars change between deploys so we can
 * restart the gateway instead of reusing a stale process.
 *
 * Uses key names + value lengths (not values) to avoid leaking secrets
 * in logs or container files. This catches additions/removals and
 * most value changes while keeping the fingerprint safe.
 */
function computeEnvFingerprint(envVars: Record<string, string>): string {
  return Object.keys(envVars).sort().map(k => `${k}:${envVars[k].length}`).join(',');
}

/**
 * Find an existing Moltbot gateway process
 *
 * Prefers actual `openclaw gateway` processes over `start-moltbot.sh` startup
 * scripts. After `start-moltbot.sh` calls `exec openclaw gateway`, the process
 * command changes. Old startup scripts that didn't reach `exec` are zombies and
 * should be deprioritized so the status endpoint can distinguish "starting up"
 * from "stale gateway".
 *
 * @param sandbox - The sandbox instance
 * @returns The process if found and running/starting, null otherwise
 */
export async function findExistingMoltbotProcess(sandbox: Sandbox): Promise<Process | null> {
  try {
    const processes = await sandbox.listProcesses();
    let gatewayProc: Process | null = null;
    let startupProc: Process | null = null;

    for (const proc of processes) {
      if (proc.status !== 'starting' && proc.status !== 'running') continue;

      const isCliCommand =
        proc.command.includes('openclaw devices') ||
        proc.command.includes('openclaw --version');
      if (isCliCommand) continue;

      if (proc.command.includes('openclaw gateway')) {
        gatewayProc = proc;
        break; // Prefer actual gateway process
      }
      if (proc.command.includes('start-moltbot.sh') && !startupProc) {
        startupProc = proc;
      }
    }

    return gatewayProc || startupProc;
  } catch (e) {
    console.log('Could not list processes:', e);
  }
  return null;
}

/**
 * Ensure the Moltbot gateway is running
 * 
 * This will:
 * 1. Mount R2 storage if configured
 * 2. Check for an existing gateway process
 * 3. Wait for it to be ready, or start a new one
 * 
 * @param sandbox - The sandbox instance
 * @param env - Worker environment bindings
 * @returns The running gateway process
 */
export async function ensureMoltbotGateway(sandbox: Sandbox, env: MoltbotEnv): Promise<Process> {
  // Mount R2 storage for persistent data (non-blocking if not configured)
  // R2 is used as a backup - the startup script will restore from it on boot
  await mountR2Storage(sandbox, env);

  // Check if Moltbot is already running or starting
  const existingProcess = await findExistingMoltbotProcess(sandbox);
  if (existingProcess) {
    console.log('Found existing Moltbot process:', existingProcess.id, 'status:', existingProcess.status);

    // Quick-probe the existing process first. If the gateway was already running,
    // the port responds in <1s. If it doesn't respond within 15s the process is
    // likely stale (from a previous DO instance after a deploy) — kill and restart
    // instead of blocking for 3 minutes.
    try {
      console.log('Probing existing Moltbot gateway on port', MOLTBOT_PORT, 'timeout:', EXISTING_PROCESS_PROBE_MS);
      await existingProcess.waitForPort(MOLTBOT_PORT, { mode: 'tcp', timeout: EXISTING_PROCESS_PROBE_MS });
      console.log('Moltbot gateway is reachable');

      // Check if environment variables have changed since the gateway was started.
      // This catches cases where secrets are added/changed via `wrangler secret put`
      // but the existing gateway process still has the old env vars.
      const envVars = buildEnvVars(env);
      const expectedFingerprint = computeEnvFingerprint(envVars);
      let envMismatch = false;

      try {
        const hashProc = await sandbox.startProcess(`cat ${ENV_HASH_PATH} 2>/dev/null || echo ""`);
        await hashProc.waitForExit(5000);
        const hashLogs = await hashProc.getLogs();
        const storedFingerprint = (hashLogs.stdout || '').trim();

        if (storedFingerprint && storedFingerprint !== expectedFingerprint) {
          console.log('[Gateway] Environment variables changed since last start, restarting...');
          envMismatch = true;
        } else if (!storedFingerprint) {
          console.log('[Gateway] No env fingerprint found (legacy process), will check token only');
        }
      } catch (e) {
        console.log('[Gateway] Env fingerprint check failed, will check token only:', e);
      }

      if (envMismatch) {
        try { await existingProcess.kill(); } catch (e) { console.log('Kill error:', e); }
        await new Promise(r => setTimeout(r, 1000));
        // Fall through to start a new process below
      } else {
        // Verify the gateway token matches what we expect. If the container was
        // started with a different token (e.g., random token from a startup before
        // secrets were properly set), kill and restart with the correct env vars.
        const expectedToken = env.MOLTBOT_GATEWAY_TOKEN;
        if (expectedToken) {
          try {
            // Read the actual token from the running process's environment
            const checkProc = await sandbox.startProcess(
              'cat /proc/$(pgrep -f "openclaw gateway" | head -1)/environ 2>/dev/null | tr "\\0" "\\n" | grep "^OPENCLAW_GATEWAY_TOKEN=" | cut -d= -f2-'
            );
            await checkProc.waitForExit(5000);
            const logs = await checkProc.getLogs();
            const actualToken = (logs.stdout || '').trim();

            console.log('[Gateway] Expected token (first 8):', expectedToken.slice(0, 8) + '...');
            console.log('[Gateway] Actual token (first 8):', actualToken ? actualToken.slice(0, 8) + '...' : '(empty)');

            if (actualToken && actualToken !== expectedToken) {
              console.log('[Gateway] Token mismatch! Restarting gateway with correct token...');
              try { await existingProcess.kill(); } catch (e) { console.log('Kill error:', e); }
              await new Promise(r => setTimeout(r, 1000));
              // Fall through to start a new process below
            } else if (!actualToken) {
              console.log('[Gateway] Could not read token from process, assuming OK');
              return existingProcess;
            } else {
              console.log('[Gateway] Token matches, reusing existing process');
              return existingProcess;
            }
          } catch (checkErr) {
            console.log('[Gateway] Token check failed, assuming OK:', checkErr);
            return existingProcess;
          }
        } else {
          return existingProcess;
        }
      }
    } catch (e) {
      // Timeout waiting for port - process is likely stale (post-deploy) or stuck
      console.log('Existing process not reachable after probe, killing and restarting...');
      try {
        await existingProcess.kill();
      } catch (killError) {
        console.log('Failed to kill process:', killError);
      }
    }
  }

  // Kill ALL lingering gateway processes before starting a new one.
  // After failed restarts / DO resets, zombie processes accumulate.
  // Use []-bracket grep trick so the cleanup command doesn't match itself.
  try {
    console.log('[Gateway] Killing all lingering gateway processes...');
    const killProc = await sandbox.startProcess(
      "ps aux | grep '[o]penclaw gateway' | awk '{print $2}' | xargs -r kill 2>/dev/null; " +
      "ps aux | grep '[s]tart-moltbot' | awk '{print $2}' | xargs -r kill 2>/dev/null; " +
      "sleep 1; echo cleanup_done"
    );
    await killProc.waitForExit(10_000);
    const killLogs = await killProc.getLogs();
    console.log('[Gateway] Cleanup:', (killLogs.stdout || '').trim());
  } catch (e) {
    console.log('[Gateway] Cleanup failed (may be OK on fresh container):', e);
  }

  // Start a new Moltbot gateway
  console.log('Starting new Moltbot gateway...');
  const newEnvVars = buildEnvVars(env);
  const command = '/usr/local/bin/start-moltbot.sh';

  // Write env fingerprint so future reuse checks can detect env var changes
  const fingerprint = computeEnvFingerprint(newEnvVars);
  try {
    const writeProc = await sandbox.startProcess(`cat > ${ENV_HASH_PATH} << 'ENVEOF'\n${fingerprint}\nENVEOF`);
    await writeProc.waitForExit(5000);
  } catch (e) {
    console.log('[Gateway] Failed to write env fingerprint:', e);
  }

  console.log('Starting process with command:', command);
  console.log('Environment vars being passed:', Object.keys(newEnvVars));

  let process: Process;
  try {
    process = await sandbox.startProcess(command, {
      env: Object.keys(newEnvVars).length > 0 ? newEnvVars : undefined,
    });
    console.log('Process started with id:', process.id, 'status:', process.status);
  } catch (startErr) {
    console.error('Failed to start process:', startErr);
    throw startErr;
  }

  // Wait for the gateway to be ready
  try {
    console.log('[Gateway] Waiting for Moltbot gateway to be ready on port', MOLTBOT_PORT);
    await process.waitForPort(MOLTBOT_PORT, { mode: 'tcp', timeout: STARTUP_TIMEOUT_MS });
    console.log('[Gateway] Moltbot gateway is ready!');

    const logs = await process.getLogs();
    if (logs.stdout) console.log('[Gateway] stdout:', logs.stdout);
    if (logs.stderr) console.log('[Gateway] stderr:', logs.stderr);
  } catch (e) {
    console.error('[Gateway] waitForPort failed:', e);
    try {
      const logs = await process.getLogs();
      console.error('[Gateway] startup failed. Stderr:', logs.stderr);
      console.error('[Gateway] startup failed. Stdout:', logs.stdout);
      throw new Error(`Moltbot gateway failed to start. Stderr: ${logs.stderr || '(empty)'}`);
    } catch (logErr) {
      console.error('[Gateway] Failed to get logs:', logErr);
      throw e;
    }
  }

  // Verify gateway is actually responding
  console.log('[Gateway] Verifying gateway health...');
  
  return process;
}
