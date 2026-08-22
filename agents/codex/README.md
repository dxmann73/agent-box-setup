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
reasoning. `[features] hooks = true` enables Codex hooks. `tui.status_line` shows model, context
usage %, session tokens, and rate-limit windows. See
[security defaults](https://developers.openai.com/codex/security). Protected paths (`.git`,
`.agents`, `.codex`) stay read-only even in writable modes.

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
