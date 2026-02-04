---
slug: gemini
name: Gemini CLI
description: Use Google Gemini CLI from the agent; supports Google OAuth login, API key, or Vertex AI credentials.
homepage: https://github.com/google-gemini/gemini-cli
---

# Gemini CLI Skill

Runs the official [Gemini CLI](https://geminicli.com/docs/) for interactive or headless prompts from the agent. Supports Google login (browser/device flow), Gemini API keys, or Vertex AI credentials.

## Setup

### Authenticate (pick one)
- **Login with Google (recommended for individuals):**
  1) Run `./scripts/login.sh` (starts `gemini`).
  2) In the terminal, choose **Login with Google**. It prints a URL and code. Open the URL in your browser, sign in, paste the code if prompted. Token is cached in `~/.gemini`.
- **Gemini API key:** Set `GEMINI_API_KEY` (from https://aistudio.google.com/app/apikey).
- **Vertex AI:** Set `GOOGLE_GENAI_USE_VERTEXAI=true`, `GOOGLE_API_KEY` **or** `GOOGLE_APPLICATION_CREDENTIALS` (service account JSON path) and `GOOGLE_CLOUD_PROJECT` (and optionally `GOOGLE_CLOUD_LOCATION`).

### Environment Variables

| Variable | Required | Description |
|----------|----------|-------------|
| `GEMINI_API_KEY` | No | Gemini API key (AI Studio). |
| `GOOGLE_API_KEY` | No | Vertex AI API key (use with `GOOGLE_GENAI_USE_VERTEXAI=true`). |
| `GOOGLE_APPLICATION_CREDENTIALS` | No | Path to service account JSON for Vertex AI. |
| `GOOGLE_CLOUD_PROJECT` | No | GCP project (required for Vertex AI or some Workspace accounts). |
| `GOOGLE_CLOUD_LOCATION` | No | GCP location for Vertex AI (e.g., `us-central1`). |
| `GOOGLE_GENAI_USE_VERTEXAI` | No | Set `true` to route via Vertex AI. |

## Available Scripts

### `login.sh`
Interactive login. Opens the Gemini CLI menu where you pick **Login with Google**; follow the browser link and code shown in the terminal.

### `prompt.sh [-m model] [--json] -- "prompt text"`
Run a headless prompt. Uses cached login or any of the env vars above.

#### Examples

```bash
# One-off prompt (text output)
./scripts/prompt.sh -- "Summarize the repo layout"

# Specify model + JSON output
GEMINI_API_KEY=sk-... ./scripts/prompt.sh -m gemini-2.5-flash --json -- "Generate a release note"
```

## Notes

- Login flow prints a URL + code; open in a local browser even if the CLI runs remotely.
- Credentials/tokens are cached under `~/.gemini`; remove that dir to sign out.
- For non-interactive/CI use, prefer API key or Vertex AI credentials.
