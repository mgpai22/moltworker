#!/bin/bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: prompt.sh [-m model] [--json] -- "prompt text"

Runs Gemini CLI in headless mode with a single prompt. Requires a cached login
(~/.gemini) or environment auth (GEMINI_API_KEY, GOOGLE_API_KEY with
GOOGLE_GENAI_USE_VERTEXAI=true, or GOOGLE_APPLICATION_CREDENTIALS with
GOOGLE_CLOUD_PROJECT).

Options:
  -m, --model <id>   Set model (e.g., gemini-2.5-flash)
  --json             Emit JSON output (uses --output-format json)
  -h, --help         Show this help

Examples:
  ./scripts/prompt.sh -- "Summarize the repo layout"
  GEMINI_API_KEY=sk-... ./scripts/prompt.sh -m gemini-2.5-flash --json -- "Generate a release note"
EOF
  exit 1
}

json=0
model=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    -m|--model)
      model="$2"; shift 2;;
    --json)
      json=1; shift;;
    -h|--help)
      usage;;
    --)
      shift; prompt_args+=("$@"); break;;
    *)
      prompt_args+=("$1"); shift;;
  esac
done

prompt="${prompt_args[*]:-}"
if [[ -z "$prompt" ]]; then
  usage
fi

cmd=(gemini --prompt "$prompt")
if [[ -n "$model" ]]; then
  cmd+=(-m "$model")
fi
if [[ $json -eq 1 ]]; then
  cmd+=(--output-format json)
fi

exec "${cmd[@]}"
