#!/bin/bash
set -euo pipefail

# Launch Gemini CLI to perform interactive login (Google OAuth, API key, or Vertex AI).
# When prompted in the TUI, choose "Login with Google" to get a URL + code,
# open the URL in your browser, authenticate, and paste/confirm the code.

exec gemini "$@"
