# 00 - Agent setup

## Claude Code

- Claude Code CLI should already be installed
- Verify with `claude --version`

### [User Settings](https://code.claude.com/docs/en/settings#settings-files)

User settings need to go to `~/.claude/settings.json`

```bash
cp configs/agents/claude/settings.json ~/.claude/settings.json
```

Settings configured:

| Setting | Value | Description |
|---------|-------|-------------|
| `model` | `opusplan` | Uses Opus for planning, Sonnet for execution |
| `permissions.defaultMode` | `bypassPermissions` | YOLO mode - no confirmation prompts |
| `spinnerVerbs` | `["Working"]` | Simplified spinner text |

### [Rules](https://code.claude.com/docs/en/memory#modular-rules-with-claude%2Frules%2F)

[User level rules](https://code.claude.com/docs/en/memory#user-level-rules) provide persistent instructions across all projects.

Source: `configs/agents/user-rules/`
Destination: `~/.claude/rules/`

```bash
mkdir -p ~/.claude/rules
cp configs/agents/user-rules/*.md ~/.claude/rules/
```

Current rules:
- `new-projects.md` - Standards for setting up new projects with agent config files

### Verification

```bash
cat ~/.claude/settings.json
ls ~/.claude/rules/
```

**Next:** Continue to `01-home-environment.md`
