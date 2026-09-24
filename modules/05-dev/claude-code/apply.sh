#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./apply.sh --target daily-host|agent-vm' "$@"
dev_require_target daily-host agent-vm
dev_require_user
curl -fsSL https://claude.ai/install.sh | bash
dev_require_commands claude
