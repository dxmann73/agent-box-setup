# 00 - Agent setup

## Global Agent Rule File

Both Claude Code and Cursor read `~/AGENTS.md` automatically. Claude Code also needs `~/CLAUDE.md`.

Source: `configs/agents/AGENTS.md`
Destination: `~/AGENTS.md` (with `~/CLAUDE.md` symlink)

```bash
ln -sf ~/projects/dave-box-setup/configs/agents/AGENTS.md ~/AGENTS.md
ln -sf ~/AGENTS.md ~/CLAUDE.md
```

## Agent-specific settings files

### Claude Code Settings

Current settings:

| Setting | Value | Description |
| ------- | ----- | ----------- |
| `model` | `opusplan` | Opus for planning, Sonnet for execution |
| `permissions.defaultMode` | `bypassPermissions` | YOLO mode - (no confirmation prompts) |
| `spinnerVerbs` | `["Working"]` | Simplified spinner text |

```bash
ln -sf ~/projects/dave-box-setup/configs/agents/claude/settings.json ~/.claude/settings.json
```

### Cursor CLI Settings

Cursor settings are stored in `~/.config/Cursor/User/settings.json`. The provided `configs/agents/cursor/settings.json` contains recommended settings to merge manually.

## User-Level Rules

User-Level Rules are a way to destructure the AGENTS.md file into smaller pieces and let the agent decide which rules need to be included in the context, instead of always including the whole AGENTS file. They provide persistent instructions across all projects.

All agents support user-level rules.

### Claude user-level rules

For reference, here the documentation about [Rules in Claude](https://code.claude.com/docs/en/memory#modular-rules-with-claude%2Frules%2F) as well as [User level rules](https://code.claude.com/docs/en/memory#user-level-rules) .

Source: `configs/agents/user-rules/`
Destination: `~/.claude/rules/`

```bash
mkdir -p ~/.claude/rules
ln -sf ~/projects/dave-box-setup/configs/agents/user-rules/*.mdc ~/.claude/rules/
```

### Cursor CLI user-level rules

TODO read and apply the documentation

```bash
mkdir -p ~/.cursor/rules
ln -sf ~/projects/dave-box-setup/configs/agents/user-rules/*.mdc ~/.cursor/rules/
```

**Next:** Continue to `01-home-environment.md`
