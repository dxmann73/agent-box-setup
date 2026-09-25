#!/usr/bin/env bash
set -Eeuo pipefail
source "$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd)/common.sh"
dev_parse_target 'Usage: ./apply.sh --target daily-host|agent-vm' "$@"
dev_require_target daily-host agent-vm
dev_require_user
dev_require_commands claude codex agent pi jq
repo=$(dev_repo_root)
link() { local target="$1" path="$2"; install -d "$(dirname "$path")"; [[ ! -e $path || -L $path ]] || { echo "Refusing to replace $path" >&2; exit 1; }; ln -sfn "$target" "$path"; }
link "$repo/agents/AGENTS.md" "$HOME/AGENTS.md"
claude_home="$HOME/CLAUDE.md"
if [[ -L $claude_home ]] && [[ $(readlink -f -- "$claude_home") == "$(readlink -f -- "$HOME/AGENTS.md")" ]]; then
    rm -- "$claude_home"
elif [[ -e $claude_home || -L $claude_home ]]; then
    printf 'Refusing to remove %s\n' "$claude_home" >&2
    exit 1
fi
link "$repo/agents" "$HOME/.agents"
link "$repo/agents/skills" "$HOME/.claude/skills"
link "$repo/agents/AGENTS.md" "$HOME/.pi/agent/AGENTS.md"
link "$repo/agents/claude/settings.json" "$HOME/.claude/settings.json"
link "$repo/agents/claude/statusline-command.sh" "$HOME/.claude/statusline-command.sh"
link "$repo/agents/codex/config.toml" "$HOME/.codex/config.toml"
link "$repo/agents/codex/hooks.json" "$HOME/.codex/hooks.json"
link "$repo/agents/cursor/hooks.json" "$HOME/.cursor/hooks.json"
link "$repo/agents/cursor/hooks" "$HOME/.cursor/hooks"
link "$repo/agents/cursor/statusline.sh" "$HOME/.cursor/statusline.sh"
"$repo/agents/cursor/apply-cli-config.sh" --permissions
find "$repo/agents/skills" -mindepth 1 -maxdepth 1 -type l -print -quit | grep -q . && { echo 'Skill roots must not be symlinks.' >&2; exit 1; } || true
