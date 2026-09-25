#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./verify.sh --target daily-host|agent-vm' "$@"
dev_require_target daily-host agent-vm
dev_require_user
repo=$(dev_repo_root)
check() { [[ -L $1 && $(readlink -f "$1") == "$2" ]]; }
check "$HOME/AGENTS.md" "$repo/agents/AGENTS.md"
[[ ! -e $HOME/CLAUDE.md && ! -L $HOME/CLAUDE.md ]]
check "$HOME/.agents" "$repo/agents"
check "$HOME/.claude/skills" "$repo/agents/skills"
check "$HOME/.pi/agent/AGENTS.md" "$repo/agents/AGENTS.md"
check "$HOME/.claude/settings.json" "$repo/agents/claude/settings.json"
check "$HOME/.codex/config.toml" "$repo/agents/codex/config.toml"
check "$HOME/.cursor/hooks" "$repo/agents/cursor/hooks"
check "$HOME/.cursor/statusline.sh" "$repo/agents/cursor/statusline.sh"
! find "$repo/agents/skills" -mindepth 1 -maxdepth 1 -type l -print -quit | grep -q .
"$repo/audit-skills.sh"
echo 'agent-config verify passed'
