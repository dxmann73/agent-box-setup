#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./verify.sh --target daily-host' "$@"
dev_require_target daily-host
dev_require_user
dev_require_commands ssh
code --list-extensions | grep -qxi ms-vscode-remote.remote-ssh
echo 'vscode-remote-ssh verify passed'
