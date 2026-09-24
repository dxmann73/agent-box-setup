#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./verify.sh --target agent-vm' "$@"
dev_require_target agent-vm
dev_require_user
dev_require_commands npx
cache_root=${PLAYWRIGHT_BROWSERS_PATH:-$HOME/.cache/ms-playwright}
find "$cache_root" -maxdepth 1 -type d -name 'chromium-*' -print -quit | grep -q .
tmp_dir=$(mktemp -d)
trap 'rm -rf -- "$tmp_dir"' EXIT
printf '%s\n' '<!doctype html><title>Playwright verification</title><main>ok</main>' >"$tmp_dir/page.html"
npx --yes playwright@latest screenshot --device='Desktop Chrome' "file://$tmp_dir/page.html" "$tmp_dir/proof.png"
[[ -s $tmp_dir/proof.png ]]
echo 'playwright-chromium verify passed'
