#!/bin/bash
# Startup script for Moltbot in Cloudflare Sandbox
# This script:
# 1. Restores config from R2 backup if available
# 2. Configures moltbot from environment variables
# 3. Starts a background sync to backup config to R2
# 4. Starts the gateway

set -e

# Kill any existing gateway AND old startup scripts so we always start fresh.
# After deploys / DO resets, zombie processes accumulate and block the port.
# Using []-bracket trick in grep avoids matching grep itself.
MY_PID=$$
EXISTING_GW_PIDS=$(ps aux | grep '[o]penclaw gateway' | awk '{print $2}' || true)
if [ -n "$EXISTING_GW_PIDS" ]; then
    echo "Found existing gateway processes, killing: $EXISTING_GW_PIDS"
    echo "$EXISTING_GW_PIDS" | xargs -r kill 2>/dev/null || true
fi
# Kill old startup scripts (except current process)
EXISTING_STARTUP_PIDS=$(ps aux | grep '[s]tart-moltbot' | awk '{print $2}' | grep -v "^${MY_PID}$" || true)
if [ -n "$EXISTING_STARTUP_PIDS" ]; then
    echo "Found old startup scripts, killing: $EXISTING_STARTUP_PIDS"
    echo "$EXISTING_STARTUP_PIDS" | xargs -r kill 2>/dev/null || true
fi
sleep 2

# Paths
CONFIG_DIR="/root/.openclaw"
CONFIG_FILE="$CONFIG_DIR/openclaw.json"
TEMPLATE_DIR="/root/.openclaw-templates"
TEMPLATE_FILE="$TEMPLATE_DIR/moltbot.json.template"
BACKUP_DIR="/data/moltbot"

echo "Config directory: $CONFIG_DIR"
echo "Backup directory: $BACKUP_DIR"

# Create config directory
mkdir -p "$CONFIG_DIR"

# ============================================================
# RESTORE FROM R2 BACKUP
# ============================================================
# Check if R2 backup exists by looking for openclaw.json (or legacy clawdbot.json)
# The BACKUP_DIR may exist but be empty if R2 was just mounted
# Note: backup structure is $BACKUP_DIR/openclaw/ and $BACKUP_DIR/skills/

# Helper function to check if R2 backup is newer than local
should_restore_from_r2() {
    local R2_SYNC_FILE="$BACKUP_DIR/.last-sync"
    local LOCAL_SYNC_FILE="$CONFIG_DIR/.last-sync"

    # If no R2 sync timestamp, don't restore
    if [ ! -f "$R2_SYNC_FILE" ]; then
        echo "No R2 sync timestamp found, skipping restore"
        return 1
    fi

    # If no local sync timestamp, restore from R2
    if [ ! -f "$LOCAL_SYNC_FILE" ]; then
        echo "No local sync timestamp, will restore from R2"
        return 0
    fi

    # Compare timestamps
    R2_TIME=$(cat "$R2_SYNC_FILE" 2>/dev/null)
    LOCAL_TIME=$(cat "$LOCAL_SYNC_FILE" 2>/dev/null)

    echo "R2 last sync: $R2_TIME"
    echo "Local last sync: $LOCAL_TIME"

    # Convert to epoch seconds for comparison
    R2_EPOCH=$(date -d "$R2_TIME" +%s 2>/dev/null || echo "0")
    LOCAL_EPOCH=$(date -d "$LOCAL_TIME" +%s 2>/dev/null || echo "0")

    if [ "$R2_EPOCH" -gt "$LOCAL_EPOCH" ]; then
        echo "R2 backup is newer, will restore"
        return 0
    else
        echo "Local data is newer or same, skipping restore"
        return 1
    fi
}

# Try new backup format first, then fall back to legacy
if [ -f "$BACKUP_DIR/openclaw/openclaw.json" ]; then
    if should_restore_from_r2; then
        echo "Restoring from R2 backup at $BACKUP_DIR/openclaw..."
        cp -a "$BACKUP_DIR/openclaw/." "$CONFIG_DIR/"
        cp -f "$BACKUP_DIR/.last-sync" "$CONFIG_DIR/.last-sync" 2>/dev/null || true
        echo "Restored config from R2 backup"
    fi
elif [ -f "$BACKUP_DIR/clawdbot/clawdbot.json" ]; then
    # Legacy backup format (pre-openclaw rename)
    if should_restore_from_r2; then
        echo "Restoring from legacy R2 backup at $BACKUP_DIR/clawdbot..."
        cp -a "$BACKUP_DIR/clawdbot/." "$CONFIG_DIR/"
        cp -f "$BACKUP_DIR/.last-sync" "$CONFIG_DIR/.last-sync" 2>/dev/null || true
        # Rename legacy config file to new name
        if [ -f "$CONFIG_DIR/clawdbot.json" ] && [ ! -f "$CONFIG_FILE" ]; then
            mv "$CONFIG_DIR/clawdbot.json" "$CONFIG_FILE"
        fi
        echo "Restored config from legacy R2 backup (migrated clawdbot -> openclaw)"
    fi
elif [ -f "$BACKUP_DIR/clawdbot.json" ]; then
    # Legacy backup format (flat structure)
    if should_restore_from_r2; then
        echo "Restoring from legacy flat R2 backup at $BACKUP_DIR..."
        cp -a "$BACKUP_DIR/." "$CONFIG_DIR/"
        cp -f "$BACKUP_DIR/.last-sync" "$CONFIG_DIR/.last-sync" 2>/dev/null || true
        # Rename legacy config file to new name
        if [ -f "$CONFIG_DIR/clawdbot.json" ] && [ ! -f "$CONFIG_FILE" ]; then
            mv "$CONFIG_DIR/clawdbot.json" "$CONFIG_FILE"
        fi
        echo "Restored config from legacy flat R2 backup (migrated clawdbot -> openclaw)"
    fi
elif [ -d "$BACKUP_DIR" ]; then
    echo "R2 mounted at $BACKUP_DIR but no backup data found yet"
else
    echo "R2 not mounted, starting fresh"
fi

# Restore skills from R2 backup if available (only if R2 is newer)
SKILLS_DIR="/root/clawd/skills"
if [ -d "$BACKUP_DIR/skills" ] && [ "$(ls -A $BACKUP_DIR/skills 2>/dev/null)" ]; then
    if should_restore_from_r2; then
        echo "Restoring skills from $BACKUP_DIR/skills..."
        mkdir -p "$SKILLS_DIR"
        cp -a "$BACKUP_DIR/skills/." "$SKILLS_DIR/"
        echo "Restored skills from R2 backup"
    fi
fi

# Restore wacli (WhatsApp CLI) session from R2 if available
# This allows WhatsApp to work without re-authenticating via QR code
# NOTE: Must use rsync instead of cp - s3fs mounted filesystems don't work well with cp
# RETRY LOGIC: R2 mount may not be ready on cold-start, so we retry with backoff
WACLI_DIR="/root/.wacli"
restore_wacli_session() {
    local max_attempts=5
    local attempt=1
    local wait_time=2

    while [ $attempt -le $max_attempts ]; do
        if [ -f "$BACKUP_DIR/wacli/session.db" ]; then
            echo "Restoring wacli session from R2 (attempt $attempt/$max_attempts)..."
            mkdir -p "$WACLI_DIR"

            if rsync -av "$BACKUP_DIR/wacli/" "$WACLI_DIR/" 2>&1; then
                # Verify file sizes match
                R2_SIZE=$(stat -c '%s' "$BACKUP_DIR/wacli/session.db" 2>/dev/null || echo "0")
                LOCAL_SIZE=$(stat -c '%s' "$WACLI_DIR/session.db" 2>/dev/null || echo "0")

                if [ "$R2_SIZE" = "$LOCAL_SIZE" ] && [ "$R2_SIZE" != "0" ]; then
                    echo "Restored wacli session (session.db: $LOCAL_SIZE bytes)"
                    return 0
                else
                    echo "Warning: wacli session restore incomplete (R2: $R2_SIZE, local: $LOCAL_SIZE)"
                fi
            else
                echo "Warning: rsync failed on attempt $attempt"
            fi
        elif [ -d "$BACKUP_DIR" ]; then
            echo "Waiting for R2 wacli files (attempt $attempt/$max_attempts)..."
        else
            echo "R2 not mounted yet, waiting (attempt $attempt/$max_attempts)..."
        fi

        if [ $attempt -lt $max_attempts ]; then
            echo "Retrying in ${wait_time}s..."
            sleep $wait_time
            wait_time=$((wait_time * 2))  # Exponential backoff: 2, 4, 8, 16s
        fi
        attempt=$((attempt + 1))
    done

    # Final check after all retries
    if [ ! -f "$BACKUP_DIR/wacli/session.db" ]; then
        echo "No wacli session in R2 after $max_attempts attempts, WhatsApp skill requires QR auth"
    fi
    return 1
}

restore_wacli_session

# ============================================================
# SEED WORKSPACE FILES (only if they don't already exist)
# ============================================================
WORKSPACE_DIR="/root/clawd"
mkdir -p "$WORKSPACE_DIR"

# HEARTBEAT.md - self-improvement loop every 30 minutes
if [ ! -f "$WORKSPACE_DIR/HEARTBEAT.md" ]; then
    echo "Creating HEARTBEAT.md..."
    cat > "$WORKSPACE_DIR/HEARTBEAT.md" << 'EOFHEARTBEAT'
# Self-Review

Review your last few responses in this session. For each decision you made, ask:
- Was there a better approach?
- Did I miss something the user implied but didn't say?
- Did I over-engineer or under-deliver?

If you find issues, append to `self-review.md` using this format:

    ## YYYY-MM-DD HH:MM
    MISS: <what you got wrong or missed>
    FIX:  <what you should do differently next time>

If nothing to log, reply with NO_REPLY.
EOFHEARTBEAT
fi

# AGENTS.md - ensure self-review.md is read on session start
if [ ! -f "$WORKSPACE_DIR/AGENTS.md" ]; then
    echo "Creating AGENTS.md..."
    cat > "$WORKSPACE_DIR/AGENTS.md" << 'EOFAGENTS'
## Session start (required)
- Read `SOUL.md`, `USER.md`, `memory.md`, and today+yesterday in `memory/`.
- Read `self-review.md` if it exists — internalize past mistakes before responding.
- Do it before responding.

## Humanizer (always active)
- Always apply the writing guidelines from `skills/humanizer/SKILL.md` to all text you produce.
- Remove all signs of AI-generated writing patterns from your responses.
- Write like a human: vary sentence length, have opinions, use simple words, avoid slop.

## Model switching
- Default model is Sonnet 4.5 — use it for quick tasks, Q&A, short edits, lookups.
- Switch to Opus 4.5 only for deep work: long research, complex multi-step plans, large refactors, or anything that will take 30+ minutes of sustained reasoning.
- When in doubt, stick with Sonnet. Opus costs more and is slower.
EOFAGENTS
fi

# Ensure humanizer skill is referenced in AGENTS.md (for existing deployments)
if [ -f "$WORKSPACE_DIR/AGENTS.md" ]; then
    if ! grep -q "humanizer" "$WORKSPACE_DIR/AGENTS.md"; then
        echo "Adding humanizer reference to existing AGENTS.md..."
        cat >> "$WORKSPACE_DIR/AGENTS.md" << 'EOFHUMANIZER'

## Humanizer (always active)
- Always apply the writing guidelines from `skills/humanizer/SKILL.md` to all text you produce.
- Remove all signs of AI-generated writing patterns from your responses.
- Write like a human: vary sentence length, have opinions, use simple words, avoid slop.

## Model switching
- Default model is Sonnet 4.5 — use it for quick tasks, Q&A, short edits, lookups.
- Switch to Opus 4.5 only for deep work: long research, complex multi-step plans, large refactors, or anything that will take 30+ minutes of sustained reasoning.
- When in doubt, stick with Sonnet. Opus costs more and is slower.
EOFHUMANIZER
    fi
fi

# If config file still doesn't exist, create from template
if [ ! -f "$CONFIG_FILE" ]; then
    echo "No existing config found, initializing from template..."
    if [ -f "$TEMPLATE_FILE" ]; then
        cp "$TEMPLATE_FILE" "$CONFIG_FILE"
    else
        # Create minimal config if template doesn't exist
        cat > "$CONFIG_FILE" << 'EOFCONFIG'
{
  "agents": {
    "defaults": {
      "workspace": "/root/clawd"
    }
  },
  "gateway": {
    "port": 18789,
    "mode": "local"
  }
}
EOFCONFIG
    fi
else
    echo "Using existing config"
fi

# ============================================================
# UPDATE CONFIG FROM ENVIRONMENT VARIABLES
# ============================================================
node << EOFNODE
const fs = require('fs');

const configPath = '/root/.openclaw/openclaw.json';
console.log('Updating config at:', configPath);
let config = {};

try {
    config = JSON.parse(fs.readFileSync(configPath, 'utf8'));
} catch (e) {
    console.log('Starting with empty config');
}

// Ensure nested objects exist
config.agents = config.agents || {};
config.agents.defaults = config.agents.defaults || {};
config.agents.defaults.model = config.agents.defaults.model || {};
config.gateway = config.gateway || {};
config.channels = config.channels || {};

// Clean up any broken anthropic provider config from previous runs
// (older versions didn't include required 'name' field)
if (config.models?.providers?.anthropic?.models) {
    const hasInvalidModels = config.models.providers.anthropic.models.some(m => !m.name);
    if (hasInvalidModels) {
        console.log('Removing broken anthropic provider config (missing model names)');
        delete config.models.providers.anthropic;
    }
}

// CRITICAL: When using OAuth token, REMOVE any apiKey from provider config.
// OpenClaw's resolveApiKeyForProvider() checks custom provider config LAST,
// but if it finds an apiKey there, it returns mode: "api-key" which sends
// x-api-key header instead of Authorization: Bearer. OAuth tokens MUST use
// Bearer header. Clean this up BEFORE writing auth profiles.
if (process.env.ANTHROPIC_OAUTH_TOKEN && config.models?.providers?.anthropic?.apiKey) {
    console.log('Removing stale apiKey from anthropic provider config (OAuth token takes precedence)');
    delete config.models.providers.anthropic.apiKey;
}

// Write auth profile for OAuth token (setup-token / Claude subscription)
// OpenClaw resolves credentials via auth profiles, NOT provider config apiKey.
// Putting the token in providerConfig.apiKey causes it to be sent as x-api-key header,
// but OAuth tokens require Authorization: Bearer header.
if (process.env.ANTHROPIC_OAUTH_TOKEN) {
    const path = require('path');
    const agentDir = '/root/.openclaw/agents/main/agent';
    fs.mkdirSync(agentDir, { recursive: true });

    const authProfiles = {
        version: 1,
        profiles: {
            'anthropic:manual': {
                type: 'token',
                provider: 'anthropic',
                token: process.env.ANTHROPIC_OAUTH_TOKEN
            }
        }
    };
    fs.writeFileSync(path.join(agentDir, 'auth-profiles.json'), JSON.stringify(authProfiles, null, 2));
    console.log('Wrote auth-profiles.json for OAuth token auth');

    // Register the auth profile in config so OpenClaw knows to use it
    config.auth = config.auth || {};
    config.auth.profiles = config.auth.profiles || {};
    config.auth.profiles['anthropic:manual'] = {
        provider: 'anthropic',
        mode: 'token'
    };
}



// Gateway configuration
config.gateway.port = 18789;
config.gateway.mode = 'local';
config.gateway.trustedProxies = ['10.1.0.0'];

// Set gateway token if provided
if (process.env.OPENCLAW_GATEWAY_TOKEN) {
    config.gateway.auth = config.gateway.auth || {};
    config.gateway.auth.token = process.env.OPENCLAW_GATEWAY_TOKEN;
}

// Allow insecure auth for the Control UI.
// When running behind a Cloudflare Worker with CF Access, the Worker handles
// user authentication. The gateway's device-signature challenge-response auth
// doesn't work through the WebSocket proxy (connections appear non-local),
// so we bypass it here and rely on CF Access for security.
config.gateway.controlUi = config.gateway.controlUi || {};
config.gateway.controlUi.allowInsecureAuth = true;

// Telegram configuration
if (process.env.TELEGRAM_BOT_TOKEN) {
    config.channels.telegram = config.channels.telegram || {};
    config.channels.telegram.botToken = process.env.TELEGRAM_BOT_TOKEN;
    config.channels.telegram.enabled = true;
    const telegramDmPolicy = process.env.TELEGRAM_DM_POLICY || 'pairing';
    config.channels.telegram.dmPolicy = telegramDmPolicy;
    if (process.env.TELEGRAM_DM_ALLOW_FROM) {
        // Explicit allowlist: "123,456,789" → ['123', '456', '789']
        config.channels.telegram.allowFrom = process.env.TELEGRAM_DM_ALLOW_FROM.split(',');
    } else if (telegramDmPolicy === 'open') {
        // "open" policy requires allowFrom: ["*"]
        config.channels.telegram.allowFrom = ['*'];
    }
}

// Discord configuration
// Note: Discord uses nested dm.policy, not flat dmPolicy like Telegram
// See: https://github.com/moltbot/moltbot/blob/v2026.1.24-1/src/config/zod-schema.providers-core.ts#L147-L155
if (process.env.DISCORD_BOT_TOKEN) {
    config.channels.discord = config.channels.discord || {};
    config.channels.discord.token = process.env.DISCORD_BOT_TOKEN;
    config.channels.discord.enabled = true;
    const discordDmPolicy = process.env.DISCORD_DM_POLICY || 'pairing';
    config.channels.discord.dm = config.channels.discord.dm || {};
    config.channels.discord.dm.policy = discordDmPolicy;

    // Build allowFrom list from DISCORD_ALLOWED_USERS (comma-separated user IDs)
    // These users are permanently whitelisted and don't need to pair after redeployment
    const allowedUsers = [];
    if (process.env.DISCORD_ALLOWED_USERS) {
        const users = process.env.DISCORD_ALLOWED_USERS.split(',').map(u => u.trim()).filter(Boolean);
        allowedUsers.push(...users);
        console.log('Discord whitelisted users:', users.join(', '));
    }

    if (discordDmPolicy === 'open') {
        // "open" policy requires allowFrom: ["*"]
        config.channels.discord.dm.allowFrom = ['*'];
    } else {
        // Use allowlist policy if we have whitelisted users, otherwise pairing
        // allowFrom contains permanently whitelisted user IDs
        config.channels.discord.dm.allowFrom = allowedUsers;
        if (allowedUsers.length > 0) {
            // Switch to allowlist mode when we have explicit users - they can DM without pairing
            // But keep pairing enabled so new users can still request access
            console.log('Discord using policy:', discordDmPolicy, 'with', allowedUsers.length, 'whitelisted user(s)');
        }
    }
}

// Slack configuration
if (process.env.SLACK_BOT_TOKEN && process.env.SLACK_APP_TOKEN) {
    config.channels.slack = config.channels.slack || {};
    config.channels.slack.botToken = process.env.SLACK_BOT_TOKEN;
    config.channels.slack.appToken = process.env.SLACK_APP_TOKEN;
    config.channels.slack.enabled = true;
}

// Base URL override (e.g., for Cloudflare AI Gateway)
// Usage: Set AI_GATEWAY_BASE_URL or ANTHROPIC_BASE_URL to your endpoint like:
//   https://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_id}/anthropic
//   https://gateway.ai.cloudflare.com/v1/{account_id}/{gateway_id}/openai
const baseUrl = (process.env.AI_GATEWAY_BASE_URL || process.env.ANTHROPIC_BASE_URL || '').replace(/\/+$/, '');
const isOpenAI = baseUrl.endsWith('/openai');

const headers = {};

if(process.env.AI_GATEWAY_API_KEY) {
    headers['cf-aig-authorization'] = 'Bearer ' + process.env.AI_GATEWAY_API_KEY;
}

if (isOpenAI) {
    // Create custom openai provider config with baseUrl override
    // Omit apiKey so moltbot falls back to OPENAI_API_KEY env var
    console.log('Configuring OpenAI provider with base URL:', baseUrl);
    config.models = config.models || {};
    config.models.providers = config.models.providers || {};
    config.models.providers.openai = {
        baseUrl: baseUrl,
        api: 'openai-responses',
        headers,
        models: [
            { id: 'gpt-5.2', name: 'GPT-5.2', contextWindow: 200000 },
            { id: 'gpt-5', name: 'GPT-5', contextWindow: 200000 },
            { id: 'gpt-4.5-preview', name: 'GPT-4.5 Preview', contextWindow: 128000 },
        ]
    };
    // Add models to the allowlist so they appear in /models
    config.agents.defaults.models = config.agents.defaults.models || {};
    config.agents.defaults.models['openai/gpt-5.2'] = { alias: 'GPT-5.2' };
    config.agents.defaults.models['openai/gpt-5'] = { alias: 'GPT-5' };
    config.agents.defaults.models['openai/gpt-4.5-preview'] = { alias: 'GPT-4.5' };
    config.agents.defaults.model.primary = 'openai/gpt-5.2';
} else if (baseUrl) {
    console.log('Configuring Anthropic provider with base URL:', baseUrl);
    config.models = config.models || {};
    config.models.providers = config.models.providers || {};
    const providerConfig = {
        baseUrl: baseUrl,
        api: 'anthropic-messages',
        headers,
        models: [
            { id: 'claude-opus-4-5-20251101', name: 'Claude Opus 4.5', contextWindow: 200000 },
            { id: 'claude-sonnet-4-5-20250929', name: 'Claude Sonnet 4.5', contextWindow: 200000 },
            { id: 'claude-haiku-4-5-20251001', name: 'Claude Haiku 4.5', contextWindow: 200000 },
        ]
    };
    // Include API key in provider config if set (required when using custom baseUrl)
    // For OAuth tokens, do NOT put them in providerConfig.apiKey — auth profiles handle it
    if (process.env.ANTHROPIC_API_KEY) {
        providerConfig.apiKey = process.env.ANTHROPIC_API_KEY;
    } else if (process.env.ANTHROPIC_OAUTH_TOKEN) {
        providerConfig.auth = "token";
        providerConfig.apiKey = process.env.ANTHROPIC_OAUTH_TOKEN;
    }
    config.models.providers.anthropic = providerConfig;
    // Add models to the allowlist so they appear in /models
    config.agents.defaults.models = config.agents.defaults.models || {};
    config.agents.defaults.models['anthropic/claude-opus-4-5-20251101'] = { alias: 'Opus 4.5' };
    config.agents.defaults.models['anthropic/claude-sonnet-4-5-20250929'] = { alias: 'Sonnet 4.5' };
    config.agents.defaults.models['anthropic/claude-haiku-4-5-20251001'] = { alias: 'Haiku 4.5' };
    config.agents.defaults.model.primary = 'anthropic/claude-sonnet-4-5-20250929';
} else if (process.env.ANTHROPIC_API_KEY) {
    // Standard API key without a custom base URL
    console.log('Configuring Anthropic provider with API key (no custom base URL)');
    config.models = config.models || {};
    config.models.providers = config.models.providers || {};
    config.models.providers.anthropic = {
        baseUrl: 'https://api.anthropic.com',
        api: 'anthropic-messages',
        apiKey: process.env.ANTHROPIC_API_KEY,
        models: [
            { id: 'claude-opus-4-5-20251101', name: 'Claude Opus 4.5', contextWindow: 200000 },
            { id: 'claude-sonnet-4-5-20250929', name: 'Claude Sonnet 4.5', contextWindow: 200000 },
            { id: 'claude-haiku-4-5-20251001', name: 'Claude Haiku 4.5', contextWindow: 200000 },
        ]
    };
    config.agents.defaults.models = config.agents.defaults.models || {};
    config.agents.defaults.models['anthropic/claude-opus-4-5-20251101'] = { alias: 'Opus 4.5' };
    config.agents.defaults.models['anthropic/claude-sonnet-4-5-20250929'] = { alias: 'Sonnet 4.5' };
    config.agents.defaults.models['anthropic/claude-haiku-4-5-20251001'] = { alias: 'Haiku 4.5' };
    config.agents.defaults.model.primary = 'anthropic/claude-sonnet-4-5-20250929';
} else if (process.env.ANTHROPIC_OAUTH_TOKEN) {
    // OAuth token without a custom base URL — use built-in Anthropic catalog.
    // Auth is handled by auth-profiles.json written above; no custom provider config needed.
    console.log('Configuring Anthropic with OAuth token via auth profiles (built-in catalog)');
    // Clean up any stale provider config that might have apiKey from a previous run
    if (config.models?.providers?.anthropic) {
        delete config.models.providers.anthropic;
    }
    config.agents.defaults.model.primary = 'anthropic/claude-sonnet-4-5';
} else {
    // No API key configured - use built-in catalog and hope env vars are picked up natively
    // Clean up any stale provider config from previous runs (e.g. expired OAuth tokens)
    if (config.models?.providers?.anthropic) {
        console.log('Removing stale anthropic provider config (no credentials available)');
        delete config.models.providers.anthropic;
    }
    config.agents.defaults.model.primary = 'anthropic/claude-sonnet-4-5';
}

// Skill configuration (register API keys so openclaw passes them to tools)
config.skills = config.skills || {};
config.skills.entries = config.skills.entries || {};

// Enable bundled skills (these are blocked by default unless explicitly allowed)
// See: https://docs.openclaw.ai/gateway/configuration - allowBundled is an allowlist for bundled skills
// Note: 'gemini' is NOT included - we use our custom skill in skills/gemini/ instead
config.skills.allowBundled = [
    'voice-call',      // Phone calls via Twilio/Telnyx/Plivo
    'coding-agent',    // Agentic coding capabilities
];
console.log('Enabled bundled skills:', config.skills.allowBundled.join(', '));

// Gemini CLI skill (OAuth login, API key, or Vertex AI)
config.skills.entries.gemini = config.skills.entries.gemini || {};
config.skills.entries.gemini.enabled = true;
const geminiEnv = {};
if (process.env.GEMINI_API_KEY) geminiEnv.GEMINI_API_KEY = process.env.GEMINI_API_KEY;
if (process.env.GOOGLE_API_KEY) geminiEnv.GOOGLE_API_KEY = process.env.GOOGLE_API_KEY;
if (process.env.GOOGLE_APPLICATION_CREDENTIALS) geminiEnv.GOOGLE_APPLICATION_CREDENTIALS = process.env.GOOGLE_APPLICATION_CREDENTIALS;
if (process.env.GOOGLE_CLOUD_PROJECT) geminiEnv.GOOGLE_CLOUD_PROJECT = process.env.GOOGLE_CLOUD_PROJECT;
if (process.env.GOOGLE_CLOUD_LOCATION) geminiEnv.GOOGLE_CLOUD_LOCATION = process.env.GOOGLE_CLOUD_LOCATION;
if (process.env.GOOGLE_GENAI_USE_VERTEXAI) geminiEnv.GOOGLE_GENAI_USE_VERTEXAI = process.env.GOOGLE_GENAI_USE_VERTEXAI;
if (Object.keys(geminiEnv).length > 0) {
    config.skills.entries.gemini.env = geminiEnv;
    console.log('Configured gemini skill with env-based auth');
} else {
    console.log('Configured gemini skill (uses cached login if no env vars set)');
}

// ImgBB skill (image uploads)
config.skills.entries.imgbb = config.skills.entries.imgbb || {};
config.skills.entries.imgbb.enabled = true;
if (process.env.IMGBB_API_KEY) {
    config.skills.entries.imgbb.env = { IMGBB_API_KEY: process.env.IMGBB_API_KEY };
    console.log('Configured imgbb skill with API key');
} else {
    console.log('Configured imgbb skill (no API key set)');
}

if (process.env.GOOGLE_PLACES_API_KEY) {
    config.skills.entries.goplaces = config.skills.entries.goplaces || {};
    config.skills.entries.goplaces.enabled = true;
    config.skills.entries.goplaces.apiKey = process.env.GOOGLE_PLACES_API_KEY;
    config.skills.entries.goplaces.env = { GOOGLE_PLACES_API_KEY: process.env.GOOGLE_PLACES_API_KEY };
    console.log('Configured goplaces skill with API key');
}

// Bird skill (X/Twitter CLI for reading tweets, search, bookmarks, news)
if (process.env.AUTH_TOKEN && process.env.CT0) {
    config.skills.entries.bird = config.skills.entries.bird || {};
    config.skills.entries.bird.enabled = true;
    config.skills.entries.bird.env = { AUTH_TOKEN: process.env.AUTH_TOKEN, CT0: process.env.CT0 };
    console.log('Configured bird skill with Twitter credentials');
}

// GitHub skill (gh CLI for issues, PRs, CI runs, API)
if (process.env.GH_TOKEN) {
    config.skills.entries.github = config.skills.entries.github || {};
    config.skills.entries.github.enabled = true;
    config.skills.entries.github.env = { GH_TOKEN: process.env.GH_TOKEN };
    console.log('Configured github skill with token');
}

// Obsidian skill (REST API for notes, search, periodic notes)
if (process.env.OBSIDIAN_API_URL && process.env.OBSIDIAN_API_KEY) {
    config.skills.entries.obsidian = config.skills.entries.obsidian || {};
    config.skills.entries.obsidian.enabled = true;
    config.skills.entries.obsidian.env = {
        OBSIDIAN_API_URL: process.env.OBSIDIAN_API_URL,
        OBSIDIAN_API_KEY: process.env.OBSIDIAN_API_KEY
    };
    console.log('Configured obsidian skill with REST API');
}

// Bitwarden skill (password manager)
if (process.env.BW_EMAIL && process.env.BW_PASSWORD) {
    config.skills.entries.bitwarden = config.skills.entries.bitwarden || {};
    config.skills.entries.bitwarden.enabled = true;
    config.skills.entries.bitwarden.env = {
        BW_EMAIL: process.env.BW_EMAIL,
        BW_PASSWORD: process.env.BW_PASSWORD
    };
    console.log('Configured bitwarden skill with credentials');
}

// Nia MCP server (knowledge agent for searching indexed repos/docs)
// NOTE: openclaw@2026.1.29 does not support "mcpServers" as a top-level config key.
// MCP servers are configured via the gateway's MCP settings, not the config file.
// The NIA_API_KEY is passed as an env var and written to .env files below
// so openclaw can pick it up through its env loading chain.
if (process.env.NIA_API_KEY) {
    console.log('NIA_API_KEY available (will be passed via env, not config)');
}

// Summarize skill (URL/YouTube/podcast/PDF summarization)
// Uses ANTHROPIC_API_KEY by default (already available from main config)
// Optional: GEMINI_API_KEY, OPENROUTER_API_KEY for additional providers
config.skills.entries.summarize = config.skills.entries.summarize || {};
config.skills.entries.summarize.enabled = true;
const summarizeEnv = {};
if (process.env.GEMINI_API_KEY) summarizeEnv.GEMINI_API_KEY = process.env.GEMINI_API_KEY;
if (process.env.OPENROUTER_API_KEY) summarizeEnv.OPENROUTER_API_KEY = process.env.OPENROUTER_API_KEY;
if (Object.keys(summarizeEnv).length > 0) {
    config.skills.entries.summarize.env = summarizeEnv;
}
console.log('Configured summarize skill (uses ANTHROPIC_API_KEY by default)');

// Write updated config
fs.writeFileSync(configPath, JSON.stringify(config, null, 2));
console.log('Configuration updated successfully');
console.log('Config:', JSON.stringify(config, null, 2));
EOFNODE

# ============================================================
# START GATEWAY
# ============================================================
# Note: R2 backup sync is handled by the Worker's cron trigger
echo "Starting Moltbot Gateway..."
echo "Gateway will be available on port 18789"

# Clean up stale lock files
rm -f /tmp/openclaw-gateway.lock 2>/dev/null || true
rm -f "$CONFIG_DIR/gateway.lock" 2>/dev/null || true

BIND_MODE="lan"
echo "Dev mode: ${OPENCLAW_DEV_MODE:-false}, Bind mode: $BIND_MODE"

# OpenClaw v2026.1.29+ requires auth for non-loopback binds.
# Generate a random token if none was provided, since the Worker handles
# its own auth layer and always communicates over localhost.
if [ -z "$OPENCLAW_GATEWAY_TOKEN" ]; then
    OPENCLAW_GATEWAY_TOKEN=$(head -c 32 /dev/urandom | base64 | tr -d '/+=' | head -c 32)
    echo "No gateway token provided, generated random token for internal use"
fi

# Write .env files so openclaw picks up skill API keys through its env loading chain.
# OpenClaw reads: process.env → .env (CWD) → ~/.openclaw/.env → inline config → skill config
# Writing to both locations ensures the keys are available regardless of how openclaw resolves them.
{
    ENV_LINES=""
    if [ -n "$GOOGLE_PLACES_API_KEY" ]; then
        ENV_LINES="${ENV_LINES}GOOGLE_PLACES_API_KEY=${GOOGLE_PLACES_API_KEY}\n"
        export GOOGLE_PLACES_API_KEY
    fi
    if [ -n "$NIA_API_KEY" ]; then
        ENV_LINES="${ENV_LINES}NIA_API_KEY=${NIA_API_KEY}\n"
        export NIA_API_KEY
    fi
    if [ -n "$GEMINI_API_KEY" ]; then
        ENV_LINES="${ENV_LINES}GEMINI_API_KEY=${GEMINI_API_KEY}\n"
        export GEMINI_API_KEY
    fi
    if [ -n "$GOOGLE_API_KEY" ]; then
        ENV_LINES="${ENV_LINES}GOOGLE_API_KEY=${GOOGLE_API_KEY}\n"
        export GOOGLE_API_KEY
    fi
    if [ -n "$GOOGLE_APPLICATION_CREDENTIALS" ]; then
        ENV_LINES="${ENV_LINES}GOOGLE_APPLICATION_CREDENTIALS=${GOOGLE_APPLICATION_CREDENTIALS}\n"
        export GOOGLE_APPLICATION_CREDENTIALS
    fi
    if [ -n "$GOOGLE_CLOUD_PROJECT" ]; then
        ENV_LINES="${ENV_LINES}GOOGLE_CLOUD_PROJECT=${GOOGLE_CLOUD_PROJECT}\n"
        export GOOGLE_CLOUD_PROJECT
    fi
    if [ -n "$GOOGLE_CLOUD_LOCATION" ]; then
        ENV_LINES="${ENV_LINES}GOOGLE_CLOUD_LOCATION=${GOOGLE_CLOUD_LOCATION}\n"
        export GOOGLE_CLOUD_LOCATION
    fi
    if [ -n "$GOOGLE_GENAI_USE_VERTEXAI" ]; then
        ENV_LINES="${ENV_LINES}GOOGLE_GENAI_USE_VERTEXAI=${GOOGLE_GENAI_USE_VERTEXAI}\n"
        export GOOGLE_GENAI_USE_VERTEXAI
    fi
    if [ -n "$IMGBB_API_KEY" ]; then
        ENV_LINES="${ENV_LINES}IMGBB_API_KEY=${IMGBB_API_KEY}\n"
        export IMGBB_API_KEY
    fi
    if [ -n "$AUTH_TOKEN" ]; then
        ENV_LINES="${ENV_LINES}AUTH_TOKEN=${AUTH_TOKEN}\n"
        export AUTH_TOKEN
    fi
    if [ -n "$CT0" ]; then
        ENV_LINES="${ENV_LINES}CT0=${CT0}\n"
        export CT0
    fi
    if [ -n "$GH_TOKEN" ]; then
        ENV_LINES="${ENV_LINES}GH_TOKEN=${GH_TOKEN}\n"
        export GH_TOKEN
    fi
    if [ -n "$OBSIDIAN_API_URL" ]; then
        ENV_LINES="${ENV_LINES}OBSIDIAN_API_URL=${OBSIDIAN_API_URL}\n"
        export OBSIDIAN_API_URL
    fi
    if [ -n "$OBSIDIAN_API_KEY" ]; then
        ENV_LINES="${ENV_LINES}OBSIDIAN_API_KEY=${OBSIDIAN_API_KEY}\n"
        export OBSIDIAN_API_KEY
    fi
    if [ -n "$BW_EMAIL" ]; then
        ENV_LINES="${ENV_LINES}BW_EMAIL=${BW_EMAIL}\n"
        export BW_EMAIL
    fi
    if [ -n "$BW_PASSWORD" ]; then
        ENV_LINES="${ENV_LINES}BW_PASSWORD=${BW_PASSWORD}\n"
        export BW_PASSWORD
    fi
    if [ -n "$GEMINI_API_KEY" ]; then
        ENV_LINES="${ENV_LINES}GEMINI_API_KEY=${GEMINI_API_KEY}\n"
        export GEMINI_API_KEY
    fi
    if [ -n "$OPENROUTER_API_KEY" ]; then
        ENV_LINES="${ENV_LINES}OPENROUTER_API_KEY=${OPENROUTER_API_KEY}\n"
        export OPENROUTER_API_KEY
    fi
    if [ -n "$ENV_LINES" ]; then
        printf "$ENV_LINES" > /root/clawd/.env
        printf "$ENV_LINES" > "$CONFIG_DIR/.env"
        echo "Wrote .env files for openclaw env loading"
    fi
}

echo "Starting gateway with token auth..."
exec openclaw gateway --port 18789 --verbose --allow-unconfigured --bind "$BIND_MODE" --token "$OPENCLAW_GATEWAY_TOKEN"
