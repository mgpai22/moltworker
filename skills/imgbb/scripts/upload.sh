#!/bin/bash
set -euo pipefail

usage() {
  cat >&2 <<'EOF'
Usage: upload.sh <file1> [file2 ...] [--json]

Upload images to ImgBB via the imgbb CLI.

Options:
  --json   Emit JSON array instead of text rows

Env vars:
  IMGBB_API_KEY   Optional API key for authenticated uploads
EOF
  exit 1
}

if [ $# -lt 1 ]; then
  usage
fi

json=0
declare -a files=()
for arg in "$@"; do
  case "$arg" in
    --json)
      json=1
      ;;
    -h|--help)
      usage
      ;;
    *)
      files+=("$arg")
      ;;
  esac
done

if [ ${#files[@]} -eq 0 ]; then
  usage
fi

if ! command -v imgbb >/dev/null 2>&1; then
  echo "imgbb CLI not found. Install with: go install github.com/wabarc/imgbb/cmd/imgbb@latest" >&2
  exit 1
fi

key_args=()
if [ -n "${IMGBB_API_KEY:-}" ]; then
  key_args=(-k "$IMGBB_API_KEY")
fi

uploads=()
for path in "${files[@]}"; do
  if [ ! -f "$path" ]; then
    echo "imgbb: $path: no such file" >&2
    continue
  fi

  output=$(imgbb "${key_args[@]}" "$path" 2>&1) || {
    echo "imgbb failed for $path: $output" >&2
    exit 1
  }

  url=$(printf '%s\n' "$output" | awk '{print $1}' | head -n 1)
  if [ -z "$url" ]; then
    echo "imgbb: no URL returned for $path" >&2
    exit 1
  fi

  uploads+=("$url|$path")

  if [ $json -eq 0 ]; then
    printf "%s\t%s\n" "$url" "$path"
  fi
done

if [ $json -eq 1 ]; then
  IMGBB_UPLOADS=$(printf '%s\n' "${uploads[@]}")
  IMGBB_UPLOADS="$IMGBB_UPLOADS" python3 - <<'PY'
import json, os

entries = []
for line in os.environ.get("IMGBB_UPLOADS", "").splitlines():
    if "|" not in line:
        continue
    url, path = line.split("|", 1)
    entries.append({"url": url.strip(), "file": path})

print(json.dumps(entries, indent=2))
PY
fi
