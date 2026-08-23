# Codex CLI

[Codex CLI](https://developers.openai.com/codex/cli) is OpenAI's terminal-based coding agent.

**Prerequisites:** ChatGPT Plus, Pro, Business, Edu, or Enterprise plan. Node.js 22+ via nvm.

## Installation

```bash
npm i -g @openai/codex
```

**Verify installation:**

```bash
codex --version
```

**Run (first launch authenticates via ChatGPT account or API key):**

```bash
codex
```

**Upgrade:**

```bash
npm i -g @openai/codex@latest
```

## Configuration

Config lives at `~/.codex/config.toml` (user-level) or `.codex/config.toml` (project-level). See
[sample config](https://developers.openai.com/codex/config-sample) and
[config reference](https://developers.openai.com/codex/config-reference).

Source: `agents/codex/config.toml`

```bash
mkdir -p ~/.codex
ln -sf ~/projects/agent-box-setup/agents/codex/config.toml ~/.codex/config.toml
```

**Verify symlink:**

```bash
ls -l ~/.codex/config.toml
```

Key settings: `approval_policy = "never"` = YOLO mode. `model_reasoning_effort = "high"` = high
reasoning. `[features] hooks = true` enables Codex hooks. See
[security defaults](https://developers.openai.com/codex/security). Protected paths (`.git`,
`.agents`, `.codex`) stay read-only even in writable modes.

### Status line

Unlike the [Claude statusline](../claude/README.md#statusline), which runs a script, Codex takes an
ordered list of **built-in** widget ids under `[tui] status_line` — no script hook, so the
`user@host`, `[CAVEMAN]` badge and custom colouring from the Claude line have no equivalent here
([openai/codex#20244](https://github.com/openai/codex/issues/20244) tracks command-backed status
lines). The order below mirrors the Claude line: location → model → context → rate limits.

```toml
[tui]
status_line = [
  "current-dir", "git-branch", "model-with-reasoning",
  "context-used", "used-tokens", "five-hour-limit", "weekly-limit",
]
```

`five-hour-limit` and `weekly-limit` are the two rate-limit windows, same pair the Claude line
renders. `status_line_use_colors` (default `true`) is the only colour control — hues come from the
active syntax theme.

The full set of item ids, none of which the
[config reference](https://developers.openai.com/codex/config-reference) enumerates:

```text
project-name  current-dir  run-state  thread-title  git-branch
context-remaining  context-used  used-tokens  total-input-tokens  total-output-tokens
five-hour-limit  weekly-limit  thread-credits  estimated-thread-cost
codex-version  thread-id  fast-mode  model-with-reasoning  reasoning  task-progress
```

Codex **silently drops** ids it does not recognise, and `codex doctor` does not flag them, so a typo
just makes a widget vanish. `verify-setup.sh` validates the list against the ids above.

`/statusline` inside the TUI edits the selection interactively and persists it straight back to
`config.toml` — which is symlinked into this repo, so changes made that way show up as a repo diff.
Commit or revert them deliberately.

**Rules:**

Codex uses [AGENTS.md](https://developers.openai.com/codex/guides/agents-md) — the global
`~/AGENTS.md` already covers this, no separate rules system needed.

**Skills:**

See [skills documentation](https://developers.openai.com/codex/skills#where-to-save-skills) for
skill placement.

## Caveman

See [../README.md#caveman](../README.md#caveman) for the clone step. Install the plugin
interactively (once):

1. `cd ~/projects/caveman && codex`
2. Type `/plugins` → Search "Caveman" → Install

Symlink the hooks file for user-level auto-start:

```bash
ln -sf ~/projects/agent-box-setup/agents/codex/hooks.json ~/.codex/hooks.json
```

The `config.toml` symlink already enables `[features] hooks = true` and caveman plugin. Caveman
fires each session via `SessionStart`.

**Next:** [../README.md#skills](../README.md#skills)
