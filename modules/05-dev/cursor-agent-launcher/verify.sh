#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./verify.sh --target daily-host' "$@"
dev_require_target daily-host
dev_require_user
repo=$(dev_repo_root)
dev_require_commands cursor-agent
[[ -L $HOME/.local/share/applications/cursor-agent.desktop && $(readlink -f "$HOME/.local/share/applications/cursor-agent.desktop") == "$repo/user-home/applications/cursor-agent.desktop" ]]
[[ -s $HOME/.local/share/icons/hicolor/256x256/apps/cursor-agent.png ]]
echo 'cursor-agent-launcher verify passed'
