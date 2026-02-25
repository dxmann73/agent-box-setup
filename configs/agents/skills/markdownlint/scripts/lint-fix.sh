#!/usr/bin/env bash
set -euo pipefail

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
cd "$repo_root"

if [[ ! -f ".markdownlint.json" ]]; then
  echo "error: .markdownlint.json not found in $repo_root" >&2
  exit 1
fi

targets=("$@")
if [[ ${#targets[@]} -eq 0 ]]; then
  targets=("**/*.md" "**/*.mdc")
fi

markdownlint_cmd=()
if command -v markdownlint >/dev/null 2>&1; then
  markdownlint_cmd=(markdownlint)
elif command -v markdownlint-cli >/dev/null 2>&1; then
  markdownlint_cmd=(markdownlint-cli)
else
  markdownlint_cmd=(npx --yes markdownlint-cli)
fi

lint_args=(--config .markdownlint.json)
if [[ -f ".markdownlintignore" ]]; then
  lint_args+=(--ignore-path .markdownlintignore)
fi

"${markdownlint_cmd[@]}" "${lint_args[@]}" --fix "${targets[@]}"
"${markdownlint_cmd[@]}" "${lint_args[@]}" "${targets[@]}"
