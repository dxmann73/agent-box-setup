# Claude Code

Claude Code is the terminal CLI named `claude`. It is separate from the optional Claude Desktop APT
package (`claude-desktop`).

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

| Setting                   | Value               | Description                           |
| ------------------------- | ------------------- | ------------------------------------- |
| `model`                   | `opus`              | Opus for planning and for execution   |
| `permissions.defaultMode` | `bypassPermissions` | YOLO mode - (no confirmation prompts) |
| `spinnerVerbs`            | `["Working"]`       | Simplified spinner text               |

Link the repo-managed settings as the source of truth:

```bash
ln -sf ~/projects/agent-box-setup/agents/claude/settings.json ~/.claude/settings.json
```

Do not replace this with a host-local settings file. If host behavior needs to change, update the
tracked setup intentionally so the repo and verification stay aligned.

**Verify settings:**

```bash
ls -l ~/.claude/settings.json && cat ~/.claude/settings.json | jq -r '.model, .permissions.defaultMode'
```

Expected output: `opus` and `bypassPermissions`

## Statusline

The statusline script renders a two-line footer in Claude Code sessions:

- **Line 1:** `user@host:/path (branch)[CAVEMAN]` — colored, git branch live from the repo, caveman
  badge when `~/.claude/.caveman-active` exists
- **Line 2:**
  `[Model] ▓▓▓▓░░░░░░ 42% (84k/200k) | 5h 63% left, 2h14m | 7d 37% left, 4d (Thu Aug 27 02:30)`
  - context bar + percentage from `context_window.used_percentage`
  - token count from `context_window.total_input_tokens` (input + cache creation + cache read — the
    same sum `used_percentage` is derived from), turns red bold at ≥150k
  - both rate-limit windows from `rate_limits.five_hour` and `rate_limits.seven_day`: the 5-hour
    session block with time left until it rolls over, then the 7-day window with days left and the
    absolute reset date
  - `[RL reset 3m20s]` appended while `/tmp/claude-rate-reset` holds a future epoch

The context bar is color-coded by usage: green (<50%), yellow (<80%), red (≥80%). The two rate-limit
segments are color-coded by **budget remaining** — plain (>50% left), yellow (≤50%), red bold (≤20%)
— and report percentage _remaining_, not consumed, so every number on the segment reads the same
direction: bigger is better, and the countdown is how long until it refills. No subprocess beyond
`jq`, `git` and `date`, so the script stays fast.

Source: `agents/claude/statusline-command.sh`

```bash
ln -sf ~/projects/agent-box-setup/agents/claude/statusline-command.sh ~/.claude/statusline-command.sh
```

**Verify:**

```bash
ls -l ~/.claude/statusline-command.sh
```

`verify-setup.sh` also covers this: it checks the symlink, that `statusLine` is wired in
`settings.json`, and that the script renders a context bar for a probe payload.

**Re-sync after changes** (or on a new machine after pulling the repo):

```bash
ln -sf ~/projects/agent-box-setup/agents/claude/statusline-command.sh ~/.claude/statusline-command.sh
```

`settings.json` already carries the full config — no further setup needed:

```json
"statusLine": {
  "type": "command",
  "command": "bash ~/.claude/statusline-command.sh",
  "padding": 1,
  "refreshInterval": 60
}
```

`refreshInterval` re-runs the script every 60s on top of the event-driven updates, so the 5-hour
countdown and the reset timers keep ticking while the session sits idle. `padding` indents the two
lines by one character. `hideVimModeIndicator` is deliberately unset — it only matters for scripts
that render `vim.mode` themselves, which this one does not.

## Caveman

Register the Caveman GitHub marketplace and install the plugin:

```bash
claude plugin marketplace add JuliusBrussee/caveman
claude plugin install caveman@caveman
```

Plugin ships `SessionStart` and `UserPromptSubmit` hooks, so caveman auto-starts every session.
`agents/claude/settings.json` already has marketplace entry + plugin enabled; the symlink above
picks it up.

## Checklist

- [ ] `claude --version` succeeds
- [ ] Claude Code is authenticated
- [ ] settings and statusline symlinks are present
- [ ] Caveman plugin is installed
