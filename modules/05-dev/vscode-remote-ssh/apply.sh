#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./apply.sh --target daily-host' "$@"
dev_require_target daily-host
dev_require_user
dev_require_commands code ssh
code --install-extension ms-vscode-remote.remote-ssh --force
