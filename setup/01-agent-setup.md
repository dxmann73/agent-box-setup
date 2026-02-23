# 01 - Agent Setup

## Agent Installation

### Claude Code

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

Configure [privacy settings](https://claude.ai/settings/data-privacy-controls) to disallow chat / prompt usage.

Run `claude` and follow the authentication prompts.

### Cursor CLI Agent

As per the [installation instructions](https://cursor.com/docs/cli/installation)

```bash
curl https://cursor.com/install -fsS | bash
```

**Verify installation:**

```bash
agent --version
```

Expected output: `2026.xx.xx-xxxxxxx` or similar

**Troubleshooting:** If `agent` command is not found, ensure `~/.local/bin` is in your PATH:

```bash
echo $PATH | grep -q "$HOME/.local/bin" && echo "✓ PATH is configured" || echo "✗ Add ~/.local/bin to PATH"
```

## Global Agent Rule File

Both Claude Code and Cursor read `~/AGENTS.md` automatically. Claude Code also needs `~/CLAUDE.md`.

Source: `configs/agents/AGENTS.md`
Destination: `~/AGENTS.md` (with `~/CLAUDE.md` symlink)

```bash
ln -sf ~/projects/agent-box-setup/configs/agents/AGENTS.md ~/AGENTS.md
ln -sf ~/AGENTS.md ~/CLAUDE.md
```

**Verify symlinks:**

```bash
ls -l ~/AGENTS.md ~/CLAUDE.md
```

Both should point to `~/projects/agent-box-setup/configs/agents/AGENTS.md`

## Agent-specific settings files

### Claude Code Settings

Current settings:

| Setting | Value | Description |
| ------- | ----- | ----------- |
| `model` | `opusplan` | Opus for planning, Sonnet for execution |
| `permissions.defaultMode` | `bypassPermissions` | YOLO mode - (no confirmation prompts) |
| `spinnerVerbs` | `["Working"]` | Simplified spinner text |

```bash
ln -sf ~/projects/agent-box-setup/configs/agents/claude/settings.json ~/.claude/settings.json
```

**Verify settings:**

```bash
ls -l ~/.claude/settings.json && cat ~/.claude/settings.json | jq -r '.model, .permissions.defaultMode'
```

Expected output: `opusplan` and `bypassPermissions`

### Cursor CLI Settings

As per the [documentation for Cursor CLI](https://cursor.com/docs/cli/reference/configuration), settings are stored in `~/.cursor/cli-config.json`. We don't touch these settings for now, as the CLI adds many of its own props to it.

### Codex

[Codex CLI](https://developers.openai.com/codex/cli) is OpenAI's terminal-based coding agent. Run it in WSL as per the [WSL setup guide](https://developers.openai.com/codex/windows#windows-subsystem-for-linux).

**Prerequisites:** ChatGPT Plus, Pro, Business, Edu, or Enterprise plan. Node.js 22+ via nvm.

**Install:**

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

**Configuration:**

Config lives at `~/.codex/config.toml` (user-level) or `.codex/config.toml` (project-level). See [sample config](https://developers.openai.com/codex/config-sample) and [config reference](https://developers.openai.com/codex/config-reference).

Source: `configs/agents/codex/config.toml`

```bash
mkdir -p ~/.codex
ln -sf ~/projects/agent-box-setup/configs/agents/codex/config.toml ~/.codex/config.toml
```

**Verify symlink:**

```bash
ls -l ~/.codex/config.toml
```

Key settings: `approval_policy = "never"` is YOLO mode (no prompts), `model_reasoning_effort = "high"` sets reasoning effort, and `tui.status_line` shows model, token/context usage, and rate-limit windows in the footer. See [security defaults](https://developers.openai.com/codex/security). Protected paths (`.git`, `.agents`, `.codex`) stay read-only even in writable modes.

**Rules:**

Codex uses [AGENTS.md](https://developers.openai.com/codex/guides/agents-md) — the global `~/AGENTS.md` already covers this, no separate rules system needed.

**Skills:**

See [skills documentation](https://developers.openai.com/codex/skills#where-to-save-skills) for skill placement.

---

## Rules, Skills, MCP, Hooks

Leerob video [Agent Skills, Rules, Subagents: Explained!](https://www.youtube.com/watch?v=L_p5GxGSB_I)

## User-Level Rules

User-Level Rules are a way to destructure the AGENTS.md file into smaller pieces and let the agent decide which rules need to be included in the context, instead of always including the whole AGENTS file. They provide persistent instructions across all projects.

All agents support user-level rules.

### Claude user-level rules

For reference, here the documentation about [Rules in Claude](https://code.claude.com/docs/en/memory#modular-rules-with-claude%2Frules%2F) as well as [User level rules](https://code.claude.com/docs/en/memory#user-level-rules) .

Source: `configs/agents/user-rules/`
Destination: `~/.claude/rules/`

```bash
mkdir -p ~/.claude/rules
ln -sf ~/projects/agent-box-setup/configs/agents/user-rules/*.mdc ~/.claude/rules/
ln -sf ~/projects/agent-box-setup/configs/agents/user-rules/*.md ~/.claude/rules/
```

Rules in subdirectories (e.g. `typescript/`) need to be linked individually:

```bash
for f in ~/projects/agent-box-setup/configs/agents/user-rules/**/*.md; do
  ln -sf "$f" ~/.claude/rules/
done
```

**Verify rules:**

```bash
ls -la ~/.claude/rules/ | wc -l
```

Expected: 5+ rules files linked

### Cursor CLI user-level rules

Rules as a means to manage context are [described here](https://cursor.com/blog/agent-best-practices#rules-static-context-for-your-project)

As per the [documentation](https://cursor.com/docs/context/rules#rule-file-format), rules should be in the home dir of the user in the `.cursor/rules` directory.

```bash
mkdir -p ~/.cursor/rules
ln -sf ~/projects/agent-box-setup/configs/agents/user-rules/*.mdc ~/.cursor/rules/
```

Subdirectory rules:

```bash
for f in ~/projects/agent-box-setup/configs/agents/user-rules/**/*.md; do
  ln -sf "$f" ~/.cursor/rules/
done
```

**Verify rules:**

```bash
ls -la ~/.cursor/rules/ | wc -l
```

Expected: 5+ rules files linked

## Skills

[official documentation](https://agentskills.io/what-are-skills). Although [skills don't really work, yet](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals), we are preparing to use skills.

Skills are taken from:

- [skills.sh](https://skills.sh/)
- [OpenAI](http://github.com/openai/skills) - already included in skills.sh
- [DeckardGer/tanstack-agent-skills](https://github.com/DeckardGer/tanstack-agent-skills) - includes TanStack Query/Router/Start/Integration skills

To make skills available, they need to be mapped to certain directories

- Agent agnostic should go to `~/.agents/skills/<skill-name>`
- For Claude this should go to `~/.claude/skills/<skill-name>`, check [the docs](https://code.claude.com/docs/en/skills)
- For Cursor this should go to `~/.cursor/skills/<skill-name>`, check [the docs](https://agentskills.io/what-are-skills)

For further reading, here is also the Codex take on [skills/evals](https://developers.openai.com/blog/eval-skills).

Source: `configs/agents/skills/`

Note: the `firecrawl` skill depends on Firecrawl CLI being installed and authenticated in `setup/03-dev-environment.md` (`firecrawl --status`).

```bash
mkdir -p ~/.claude/skills ~/.cursor/skills ~/.agents/skills

for skill in ~/projects/agent-box-setup/configs/agents/skills/*/; do
  name=$(basename "$skill")
  ln -sfn "$skill" ~/.claude/skills/"$name"
  ln -sfn "$skill" ~/.cursor/skills/"$name"
  ln -sfn "$skill" ~/.agents/skills/"$name"
done
```

**Verify skills:**

```bash
echo "Claude skills:" && ls ~/.claude/skills/ | wc -l
echo "Cursor skills:" && ls ~/.cursor/skills/ | wc -l
echo "Agent skills:" && ls ~/.agents/skills/ | wc -l
```

Expected: Same count for all three (should match number of skill directories)

**Verify linked skills against `configs/agents/skills/`:**

```bash
SOURCE_DIR=~/projects/agent-box-setup/configs/agents/skills

for dir in ~/.claude/skills ~/.cursor/skills ~/.agents/skills; do
  echo "[$dir]"
  for skill_path in "$SOURCE_DIR"/*/; do
    skill=$(basename "$skill_path")
    if [ -L "$dir/$skill" ] || [ -d "$dir/$skill" ]; then
      echo "  ✓ $skill"
    else
      echo "  ✗ $skill"
    fi
  done
done
```

Expected: every skill directory under `configs/agents/skills/` shows `✓` for all three link targets.

---

## Complete Verification

Run all verification commands to ensure setup is complete:

```bash
echo "=== Agent Binaries ===" && \
claude --version && \
agent --version && \
codex --version && \
echo -e "\n=== Config Files ===" && \
ls -l ~/AGENTS.md ~/CLAUDE.md && \
echo -e "\n=== Settings ===" && \
ls -l ~/.claude/settings.json && \
ls -l ~/.codex/config.toml && \
echo -e "\n=== Rules Count ===" && \
echo "Claude rules: $(ls ~/.claude/rules/ 2>/dev/null | wc -l)" && \
echo "Cursor rules: $(ls ~/.cursor/rules/ 2>/dev/null | wc -l)" && \
echo -e "\n=== Skills Count ===" && \
echo "Claude skills: $(ls ~/.claude/skills/ 2>/dev/null | wc -l)" && \
echo "Cursor skills: $(ls ~/.cursor/skills/ 2>/dev/null | wc -l)"
```

**Next:** Continue to `02-core-tools.md`
