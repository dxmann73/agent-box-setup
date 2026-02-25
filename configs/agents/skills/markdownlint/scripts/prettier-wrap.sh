#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"

if ! command -v jq >/dev/null 2>&1; then
  echo "error: jq is required to read .markdownlint.json" >&2
  exit 1
fi

line_width=""
if [[ -f ".markdownlint.json" ]]; then
  line_width="$(jq -r '.MD013.line_length // empty' .markdownlint.json)"
fi

if [[ -z "$line_width" || ! "$line_width" =~ ^[0-9]+$ ]]; then
  line_width="120"
fi

targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
  targets=("**/*.md" "**/*.mdc")
fi

npx --yes prettier --ignore-path .markdownlintignore --print-width "$line_width" --prose-wrap always \
  --parser markdown --write "${targets[@]}"
