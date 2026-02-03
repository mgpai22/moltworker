# Adding Skills to Moltworker

This guide explains how to create and add new skills to the Moltworker bot.

## What is a Skill?

A skill is a self-contained module that extends the bot's capabilities. Skills typically wrap CLI tools, APIs, or provide specialized functionality that the AI agent can use during conversations.

Examples of existing skills:
- **bird** - X/Twitter API client for reading tweets, search, bookmarks
- **bitwarden** - Password manager CLI integration
- **nia** - Code/documentation indexing and search
- **cloudflare-browser** - Headless browser automation via CDP

## Skill Directory Structure

Each skill lives in `skills/<skill-name>/` with this structure:

```
skills/
└── my-skill/
    ├── SKILL.md          # Required: Full documentation with YAML frontmatter
    ├── README.md         # Optional: Quick start guide
    └── scripts/          # Required: Executable scripts
        ├── command1.sh
        ├── command2.sh
        └── helper.js     # Can be any language
```

## Creating a New Skill

### Step 1: Create the Directory Structure

```bash
mkdir -p skills/my-skill/scripts
```

### Step 2: Create SKILL.md

The `SKILL.md` file is the primary documentation. It **must** have YAML frontmatter:

```markdown
---
slug: my-skill
name: My Skill
description: Brief description of what the skill does (shown in skill list).
homepage: https://example.com
---

# My Skill

Detailed documentation about the skill.

## Setup

Instructions for getting credentials/API keys.

## Available Scripts

### script-name.sh
Description and usage examples.

## Environment Variables

| Variable | Description |
|----------|-------------|
| `MY_API_KEY` | API key for the service |

## Examples

Code examples showing common use cases.
```

#### Frontmatter Fields

| Field | Required | Description |
|-------|----------|-------------|
| `slug` | Yes | URL-safe identifier (lowercase, hyphens) |
| `name` | Yes | Human-readable display name |
| `description` | Yes | Brief description for skill listings |
| `homepage` | No | Link to upstream project/docs |

### Step 3: Create Scripts

Scripts are the executable commands the AI can run. They can be written in any language (bash, Node.js, Python, etc.).

#### Bash Script Template

```bash
#!/bin/bash
# Brief description of what this script does
# Usage: script-name.sh <required-arg> [optional-arg]

set -e

# Validate arguments
if [ -z "$1" ]; then
    echo "Usage: script-name.sh <required-arg> [options]" >&2
    echo "Options: --json, --verbose" >&2
    exit 1
fi

# Check for required environment variables
if [ -z "$MY_API_KEY" ]; then
    echo "Error: MY_API_KEY environment variable not set" >&2
    exit 1
fi

# Execute the command
my-cli-tool "$@"
```

#### Node.js Script Template

```javascript
#!/usr/bin/env node
/**
 * Brief description of what this script does
 * Usage: node script-name.js <url> [output]
 */

const API_KEY = process.env.MY_API_KEY;
if (!API_KEY) {
  console.error('Error: MY_API_KEY environment variable not set');
  process.exit(1);
}

const arg1 = process.argv[2];
if (!arg1) {
  console.error('Usage: node script-name.js <url> [output]');
  process.exit(1);
}

// Implementation...
```

#### Python Script Template

```python
#!/usr/bin/env python3
"""Brief description of what this script does.

Usage: script-name.py <query> [--json]
"""

import os
import sys

API_KEY = os.environ.get('MY_API_KEY')
if not API_KEY:
    print("Error: MY_API_KEY environment variable not set", file=sys.stderr)
    sys.exit(1)

if len(sys.argv) < 2:
    print("Usage: script-name.py <query> [--json]", file=sys.stderr)
    sys.exit(1)

# Implementation...
```

### Step 4: Make Scripts Executable

```bash
chmod +x skills/my-skill/scripts/*.sh
chmod +x skills/my-skill/scripts/*.js
chmod +x skills/my-skill/scripts/*.py
```

### Step 5: Add Dependencies to Dockerfile (if needed)

If your skill requires system packages or CLI tools, add them to the `Dockerfile`:

```dockerfile
# Install my-cli-tool
RUN npm install -g my-cli-tool \
    && my-cli-tool --version

# Or for a binary download
RUN curl -fsSL https://example.com/my-tool.tar.gz -o /tmp/my-tool.tar.gz \
    && tar -xzf /tmp/my-tool.tar.gz -C /usr/local/bin my-tool \
    && rm /tmp/my-tool.tar.gz \
    && my-tool --version
```

The Dockerfile already includes:
- Node.js 22
- npm, pnpm
- uv (Python package manager)
- curl, jq

### Step 6: Configure Environment Variables

If your skill needs API keys or secrets, add handling in `start-moltbot.sh`:

#### 1. Add skill configuration (in the Node.js section, around line 470):

```javascript
// My Skill (description)
if (process.env.MY_API_KEY) {
    config.skills.entries['my-skill'] = config.skills.entries['my-skill'] || {};
    config.skills.entries['my-skill'].enabled = true;
    config.skills.entries['my-skill'].env = { MY_API_KEY: process.env.MY_API_KEY };
    console.log('Configured my-skill with API key');
}
```

#### 2. Add to .env file generation (in the bash section, around line 525):

```bash
if [ -n "$MY_API_KEY" ]; then
    ENV_LINES="${ENV_LINES}MY_API_KEY=${MY_API_KEY}\n"
    export MY_API_KEY
fi
```

### Step 7: Set Secrets via Wrangler

```bash
# Set the secret
echo "your-api-key-here" | npx wrangler secret put MY_API_KEY

# Verify it was set
npx wrangler secret list
```

### Step 8: Deploy

```bash
npm run deploy
```

Before deploying, bump `CACHE_BUST` in the `Dockerfile` to force a fresh image build so new skills and binaries are included.

This rebuilds the Docker image (which copies `skills/` to `/root/clawd/skills/`) and deploys to Cloudflare.

## Best Practices

### Script Design

1. **Single responsibility** - Each script should do one thing well
2. **Clear usage messages** - Show usage when args are missing
3. **Exit codes** - Use `exit 1` for errors, `exit 0` for success
4. **Stderr for errors** - Use `>&2` for error messages
5. **Support --json** - Return structured output when possible

### Documentation

1. **Complete examples** - Show realistic use cases
2. **Environment variables** - Document all required vars
3. **Error handling** - Explain common errors and solutions
4. **Prerequisites** - List any setup steps

### Security

1. **Never hardcode secrets** - Always use environment variables
2. **Validate input** - Check arguments before using them
3. **Don't log secrets** - Be careful with debug output
4. **Use set -e** - Exit on first error in bash scripts

## Example: Complete Skill

Here's a minimal but complete skill example:

### skills/weather/SKILL.md

```markdown
---
slug: weather
name: Weather
description: Get weather forecasts using wttr.in API.
homepage: https://wttr.in
---

# Weather Skill

Get weather forecasts for any location using the wttr.in API.

## Setup

No API key required - wttr.in is a free service.

## Available Scripts

### forecast.sh
Get weather forecast for a location.

```bash
./scripts/forecast.sh "New York"
./scripts/forecast.sh "London" --json
```

### current.sh
Get current conditions only.

```bash
./scripts/current.sh "Tokyo"
```

## Examples

```bash
# Full forecast
./scripts/forecast.sh "San Francisco"

# JSON output for parsing
./scripts/forecast.sh "Paris" --json | jq '.current_condition[0].temp_C'
```
```

### skills/weather/scripts/forecast.sh

```bash
#!/bin/bash
# Get weather forecast for a location
# Usage: forecast.sh <location> [--json]

set -e

if [ -z "$1" ]; then
    echo "Usage: forecast.sh <location> [--json]" >&2
    exit 1
fi

LOCATION="$1"
FORMAT=""

if [ "$2" = "--json" ]; then
    FORMAT="?format=j1"
fi

curl -s "https://wttr.in/${LOCATION}${FORMAT}"
```

### skills/weather/scripts/current.sh

```bash
#!/bin/bash
# Get current weather conditions
# Usage: current.sh <location>

set -e

if [ -z "$1" ]; then
    echo "Usage: current.sh <location>" >&2
    exit 1
fi

curl -s "https://wttr.in/$1?format=%l:+%c+%t+%h+%w"
```

## Skill Categories

### API Wrapper Skills
Wrap external APIs with authentication handling.
- Store API keys in Wrangler secrets
- Add env var handling to start-moltbot.sh
- Examples: bird, nia, bitwarden

### CLI Tool Skills
Wrap command-line tools that are installed in the container.
- Add installation to Dockerfile
- Scripts just invoke the CLI with proper args
- Examples: goplaces, bitwarden

### Self-Contained Skills
Pure scripts that don't need external dependencies.
- Just scripts with standard unix tools (curl, jq, etc.)
- Examples: weather (hypothetical)

### Browser/Automation Skills
Control headless browsers or automate tasks.
- May need special bindings (CDP, Puppeteer)
- Examples: cloudflare-browser

## Debugging Skills

### Test locally

```bash
# Set env vars
export MY_API_KEY="test-key"

# Run script directly
./skills/my-skill/scripts/command.sh arg1 arg2
```

### Check container logs

After deploying, check the gateway logs for skill loading:
```
Configured my-skill with API key
```

### Verify files are copied

The Dockerfile copies skills with:
```dockerfile
COPY skills/ /root/clawd/skills/
```

All files in `skills/` are automatically included.

## Troubleshooting

### "Command not found"

- Check the script has a shebang (`#!/bin/bash` or `#!/usr/bin/env node`)
- Verify the script is executable (`chmod +x`)
- For node/python, ensure the runtime is installed in the Dockerfile

### "Environment variable not set"

- Set the secret via wrangler: `npx wrangler secret put VAR_NAME`
- Add handling in start-moltbot.sh
- Redeploy after adding the secret

### "Permission denied"

- Make scripts executable: `chmod +x scripts/*`
- Commit the executable bit to git

### Skill not appearing

- Verify SKILL.md has valid YAML frontmatter
- Check the slug matches the directory name
- Redeploy to update the container
