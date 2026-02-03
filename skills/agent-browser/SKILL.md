---
slug: agent-browser
name: Agent Browser
description: Headless browser automation CLI for AI agents - navigate, click, fill forms, take screenshots.
homepage: https://agent-browser.dev
---

# Agent Browser Skill

Headless browser automation CLI designed for AI agents. Navigate websites, interact with elements, fill forms, and capture screenshots programmatically.

## Core Workflow

The recommended workflow for AI agents:

```bash
# 1. Navigate to page
agent-browser open example.com

# 2. Get snapshot with element refs
agent-browser snapshot -i
# Output:
# - heading "Example Domain" [ref=e1]
# - button "Submit" [ref=e2]
# - textbox "Email" [ref=e3]

# 3. Interact using refs from snapshot
agent-browser click @e2
agent-browser fill @e3 "test@example.com"

# 4. Re-snapshot after page changes
agent-browser snapshot -i

# 5. Screenshot and close
agent-browser screenshot result.png
agent-browser close
```

## Available Scripts

### Navigation
| Script | Description |
|--------|-------------|
| `open.sh <url>` | Navigate to URL |
| `back.sh` | Go back in history |
| `forward.sh` | Go forward in history |
| `reload.sh` | Reload current page |
| `close.sh` | Close browser |

### Page Analysis
| Script | Description |
|--------|-------------|
| `snapshot.sh` | Get accessibility tree with refs |
| `snapshot-interactive.sh` | Get interactive elements only |
| `snapshot-json.sh` | Get snapshot as JSON |
| `screenshot.sh [path]` | Take screenshot |
| `screenshot-full.sh [path]` | Full page screenshot |

### Element Interaction
| Script | Description |
|--------|-------------|
| `click.sh <selector>` | Click element |
| `dblclick.sh <selector>` | Double-click element |
| `fill.sh <selector> <text>` | Clear and fill input |
| `type.sh <selector> <text>` | Type text (no clear) |
| `press.sh <key>` | Press key (Enter, Tab, etc.) |
| `hover.sh <selector>` | Hover over element |
| `select.sh <selector> <value>` | Select dropdown option |
| `check.sh <selector>` | Check checkbox |
| `uncheck.sh <selector>` | Uncheck checkbox |
| `scroll.sh <direction> [pixels]` | Scroll page |

### Get Information
| Script | Description |
|--------|-------------|
| `get-text.sh <selector>` | Get element text |
| `get-html.sh <selector>` | Get element HTML |
| `get-value.sh <selector>` | Get input value |
| `get-attr.sh <selector> <attr>` | Get attribute |
| `get-title.sh` | Get page title |
| `get-url.sh` | Get current URL |
| `get-count.sh <selector>` | Count matching elements |

### Wait & Sync
| Script | Description |
|--------|-------------|
| `wait.sh <selector>` | Wait for element |
| `wait-text.sh <text>` | Wait for text to appear |
| `wait-url.sh <pattern>` | Wait for URL pattern |
| `wait-load.sh` | Wait for network idle |
| `wait-ms.sh <milliseconds>` | Wait for time |

### Advanced
| Script | Description |
|--------|-------------|
| `eval.sh <javascript>` | Execute JavaScript |
| `state-save.sh <path>` | Save auth/session state |
| `state-load.sh <path>` | Load auth/session state |
| `session-list.sh` | List active sessions |
| `trace-start.sh [path]` | Start trace recording |
| `trace-stop.sh [path]` | Stop and save trace |

## Selectors

### Refs (Recommended)
Use refs from snapshots for reliable element selection:

```bash
# Get snapshot first
agent-browser snapshot -i
# - button "Login" [ref=e1]
# - textbox "Email" [ref=e2]

# Use refs with @ prefix
agent-browser click @e1
agent-browser fill @e2 "user@example.com"
```

### CSS Selectors
Standard CSS selectors also work:

```bash
agent-browser click "#submit-btn"
agent-browser fill "input[name='email']" "test@example.com"
agent-browser click ".nav-link:first-child"
```

## Examples

### Login to a website
```bash
./scripts/open.sh "https://example.com/login"
./scripts/snapshot-interactive.sh
# - textbox "Email" [ref=e1]
# - textbox "Password" [ref=e2]
# - button "Sign In" [ref=e3]

./scripts/fill.sh @e1 "user@example.com"
./scripts/fill.sh @e2 "password123"
./scripts/click.sh @e3
./scripts/wait-url.sh "**/dashboard"
./scripts/screenshot.sh "logged-in.png"
```

### Fill a form
```bash
./scripts/open.sh "https://example.com/contact"
./scripts/snapshot-interactive.sh
./scripts/fill.sh @e1 "John Doe"
./scripts/fill.sh @e2 "john@example.com"
./scripts/fill.sh @e3 "Hello, this is my message"
./scripts/click.sh @e4  # Submit button
./scripts/wait-text.sh "Thank you"
```

### Scrape page content
```bash
./scripts/open.sh "https://example.com/article"
./scripts/get-title.sh
./scripts/get-text.sh "article"
./scripts/screenshot-full.sh "article.png"
./scripts/close.sh
```

### Multi-page navigation
```bash
./scripts/open.sh "https://example.com"
./scripts/snapshot-interactive.sh
./scripts/click.sh @e2  # Click a link
./scripts/wait-load.sh
./scripts/snapshot-interactive.sh
./scripts/back.sh
./scripts/snapshot-interactive.sh
```

## Sessions

Run multiple isolated browser instances:

```bash
# Different sessions
AGENT_BROWSER_SESSION=agent1 ./scripts/open.sh "site-a.com"
AGENT_BROWSER_SESSION=agent2 ./scripts/open.sh "site-b.com"

# List sessions
./scripts/session-list.sh
```

## Tips

- **Always snapshot first** - Get refs before interacting
- **Re-snapshot after changes** - Page state changes after clicks/navigation
- **Use refs over CSS** - Refs are more reliable for dynamic pages
- **Wait for stability** - Use wait commands before interacting
- **Save auth state** - Use `state-save.sh` to persist login sessions
