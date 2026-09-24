#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./verify.sh --target daily-host|agent-vm' "$@"
dev_require_target daily-host agent-vm
dev_require_user
codex --version
