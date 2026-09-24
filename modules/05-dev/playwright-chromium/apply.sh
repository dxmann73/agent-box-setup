#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./apply.sh --target agent-vm' "$@"
dev_require_target agent-vm
dev_require_user
dev_require_commands npx
sudo npx --yes playwright@latest install-deps chromium
npx --yes playwright@latest install chromium
