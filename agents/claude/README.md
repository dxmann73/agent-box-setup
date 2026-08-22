# Claude Code

## Installation

Claude should already be installed. If not, install [Claude](https://code.claude.com/docs/en/setup)

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

**Verify installation:**

```bash
claude --version
```

Expected output: `2.x.x (Claude Code)` or similar

**Configure and authenticate:**

Configure [privacy settings](https://claude.ai/settings/data-privacy-controls) to disallow chat /
prompt usage.

Run `claude` and follow the authentication prompts.

## Settings

Current settings:

| Setting                   | Value               | Description                             |
| ------------------------- | ------------------- | --------------------------------------- |
| `model`                   | `opusplan`          | Opus for planning, Sonnet for execution |
| `permissions.defaultMode` | `bypassPermissions` | YOLO mode - (no confirmation prompts)   |
| `spinnerVerbs`            | `["Working"]`       | Simplified spinner text                 |

```bash
ln -sf ~/projects/agent-box-setup/agents/claude/settings.json ~/.claude/settings.json
```

**Verify settings:**

```bash
ls -l ~/.claude/settings.json && cat ~/.claude/settings.json | jq -r '.model, .permissions.defaultMode'
```

Expected output: `opusplan` and `bypassPermissions`

## Statusline

The statusline script renders a two-line footer in Claude Code sessions:

- **Line 1:** `user@host:/path (branch)` — colored, live from git
- **Line 2:** `[Model] ▓▓▓▓░░░░░░ 42% | $0.03 session / $8.34 today / block 3h41m left` — context
  bar
  - cached cost/block data from `ccusage`

The context bar is color-coded: green (<50%), yellow (<80%), red (≥80%). Cost/block data is fetched
via `npx ccusage@latest` and cached in `/tmp` for ~10s to keep the statusline fast.

Source: `agents/claude/statusline-command.sh`

```bash
ln -sf ~/projects/agent-box-setup/agents/claude/statusline-command.sh ~/.claude/statusline-command.sh
```

**Verify:**

```bash
ls -l ~/.claude/statusline-command.sh
```

**Re-sync after changes** (or on a new machine after pulling the repo):

```bash
ln -sf ~/projects/agent-box-setup/agents/claude/statusline-command.sh ~/.claude/statusline-command.sh
```

The `settings.json` already points to `bash ~/.claude/statusline-command.sh` — no further config
needed.

## Caveman

See [../README.md#caveman](../README.md#caveman) for the clone step. Register the marketplace and
install the plugin:

```bash
claude plugin marketplace add JuliusBrussee/caveman
claude plugin install caveman@caveman
```

Plugin ships `SessionStart` and `UserPromptSubmit` hooks, so caveman auto-starts every session.
`agents/claude/settings.json` already has marketplace entry + plugin enabled; the symlink above
picks it up.

**Next:** [../cursor/README.md](../cursor/README.md)
