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

Configure [privacy settings](https://claude.ai/settings/data-privacy-controls) to disallow chat /
prompt usage.

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

Source: `configs/agents/AGENTS.md` Destination: `~/AGENTS.md` (with `~/CLAUDE.md` symlink)

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

| Setting                   | Value               | Description                             |
| ------------------------- | ------------------- | --------------------------------------- |
| `model`                   | `opusplan`          | Opus for planning, Sonnet for execution |
| `permissions.defaultMode` | `bypassPermissions` | YOLO mode - (no confirmation prompts)   |
| `spinnerVerbs`            | `["Working"]`       | Simplified spinner text                 |

```bash
ln -sf ~/projects/agent-box-setup/configs/agents/claude/settings.json ~/.claude/settings.json
```

**Verify settings:**

```bash
ls -l ~/.claude/settings.json && cat ~/.claude/settings.json | jq -r '.model, .permissions.defaultMode'
```

Expected output: `opusplan` and `bypassPermissions`

### Claude Code Statusline

The statusline script renders a two-line footer in Claude Code sessions:

- **Line 1:** `user@host:/path (branch)` — colored, live from git
- **Line 2:** `[Model] ▓▓▓▓░░░░░░ 42% | $0.03 session / $8.34 today / block 3h41m left` — context
  bar
  - cached cost/block data from `ccusage`

The context bar is color-coded: green (<50%), yellow (<80%), red (≥80%). Cost/block data is fetched
via `npx ccusage@latest` and cached in `/tmp` for ~10s to keep the statusline fast.

Source: `configs/agents/claude/statusline-command.sh`

```bash
ln -sf ~/projects/agent-box-setup/configs/agents/claude/statusline-command.sh ~/.claude/statusline-command.sh
```

**Verify:**

```bash
ls -l ~/.claude/statusline-command.sh
```

**Re-sync after changes** (or on a new machine after pulling the repo):

```bash
ln -sf ~/projects/agent-box-setup/configs/agents/claude/statusline-command.sh ~/.claude/statusline-command.sh
```

The `settings.json` already points to `bash ~/.claude/statusline-command.sh` — no further config
needed.

### Cursor CLI Settings

As per the [documentation for Cursor CLI](https://cursor.com/docs/cli/reference/configuration),
settings are stored in `~/.cursor/cli-config.json`. Cursor manages this file directly — do not
symlink it.

`configs/agents/cursor/cli-config.json` is kept as a reference snapshot (credentials masked) to
compare settings across machines. On setup, diff and reconcile the two:

```bash
diff <(jq 'del(.authInfo, .privacyCache)' \
        ~/projects/agent-box-setup/configs/agents/cursor/cli-config.json) \
     <(jq 'del(.authInfo, .privacyCache)' \
        ~/.cursor/cli-config.json)
```

Copy any desired settings from the reference into `~/.cursor/cli-config.json` manually.

**Key settings:**

- `permissions.allow: ["Shell(*)"]` — auto-approve all shell commands (yolo mode). The
  `approvalMode` field itself is Cursor-managed; use `--force` / `--yolo` CLI flags to skip approval
  prompts at invocation time.
- `sandbox.mode: "disabled"` — no sandboxing.
- `attribution.attributeCommitsToAgent: true` — commits are attributed to the agent.

### Codex

[Codex CLI](https://developers.openai.com/codex/cli) is OpenAI's terminal-based coding agent. Run it
in WSL as per the
[WSL setup guide](https://developers.openai.com/codex/windows#windows-subsystem-for-linux).

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

Config lives at `~/.codex/config.toml` (user-level) or `.codex/config.toml` (project-level). See
[sample config](https://developers.openai.com/codex/config-sample) and
[config reference](https://developers.openai.com/codex/config-reference).

Source: `configs/agents/codex/config.toml`

```bash
mkdir -p ~/.codex
ln -sf ~/projects/agent-box-setup/configs/agents/codex/config.toml ~/.codex/config.toml
```

**Verify symlink:**

```bash
ls -l ~/.codex/config.toml
```

Key settings: `approval_policy = "never"` is YOLO mode (no prompts),
`model_reasoning_effort = "medium"` sets reasoning effort, and `tui.status_line` shows model,
context usage percentage, context window size, session token counters, and rate-limit windows in the
footer. Codex currently does not expose a built-in status item for the raw number of tokens in the
current context window, only percentage used/remaining plus the total window size. See
[security defaults](https://developers.openai.com/codex/security). Protected paths (`.git`,
`.agents`, `.codex`) stay read-only even in writable modes.

**Rules:**

Codex uses [AGENTS.md](https://developers.openai.com/codex/guides/agents-md) — the global
`~/AGENTS.md` already covers this, no separate rules system needed.

**Skills:**

See [skills documentation](https://developers.openai.com/codex/skills#where-to-save-skills) for
skill placement.

---

## Rules, Skills, MCP, Hooks

Leerob video
[Agent Skills, Rules, Subagents: Explained!](https://www.youtube.com/watch?v=L_p5GxGSB_I)

## User-Level Rules

User-Level Rules are a way to destructure the AGENTS.md file into smaller pieces and let the agent
decide which rules need to be included in the context, instead of always including the whole AGENTS
file. They provide persistent instructions across all projects.

All agents support user-level rules.

### Claude user-level rules

For reference, here the documentation about
[Rules in Claude](https://code.claude.com/docs/en/memory#modular-rules-with-claude%2Frules%2F) as
well as [User level rules](https://code.claude.com/docs/en/memory#user-level-rules) .

Source: `configs/agents/user-rules/` Destination: `~/.claude/rules/`

```bash
SOURCE_RULES=~/projects/agent-box-setup/configs/agents/user-rules
mkdir -p ~/.claude/rules
# Remove stale/dangling links from removed rules
find ~/.claude/rules -maxdepth 1 -xtype l -delete
find "$SOURCE_RULES" -type f \( -name '*.md' -o -name '*.mdc' \) -print0 | while IFS= read -r -d '' f; do
  ln -sfn "$f" ~/.claude/rules/"$(basename "$f")"
done
```

**Verify rules:**

```bash
count_rules() { find "$1" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l; }
echo "Source rules: $(count_rules ~/projects/agent-box-setup/configs/agents/user-rules)"
echo "Claude rules: $(count_rules ~/.claude/rules)"
```

Expected: `Claude rules` equals `Source rules`

### Cursor CLI user-level rules

Rules as a means to manage context are
[described here](https://cursor.com/blog/agent-best-practices#rules-static-context-for-your-project)

As per the [documentation](https://cursor.com/docs/context/rules#rule-file-format), rules should be
in the home dir of the user in the `.cursor/rules` directory.

```bash
SOURCE_RULES=~/projects/agent-box-setup/configs/agents/user-rules
mkdir -p ~/.cursor/rules
# Remove stale/dangling links from removed rules
find ~/.cursor/rules -maxdepth 1 -xtype l -delete
find "$SOURCE_RULES" -type f \( -name '*.md' -o -name '*.mdc' \) -print0 | while IFS= read -r -d '' f; do
  ln -sfn "$f" ~/.cursor/rules/"$(basename "$f")"
done
```

**Verify rules:**

```bash
count_rules() { find "$1" -mindepth 1 -maxdepth 1 2>/dev/null | wc -l; }
echo "Source rules: $(count_rules ~/projects/agent-box-setup/configs/agents/user-rules)"
echo "Cursor rules: $(count_rules ~/.cursor/rules)"
```

Expected: `Cursor rules` equals `Source rules`

## Skills

[Official documentation](https://agentskills.io/what-are-skills). For further reading, see also the
Codex take on [skills/evals](https://developers.openai.com/blog/eval-skills).

Skills are managed via the [skills CLI](https://github.com/vercel-labs/skills) (`npx skills`).
Because `~/.agents` is symlinked to `configs/agents/`, a global install (`-g`) writes skill files
directly into `configs/agents/skills/` and the lock file into `configs/agents/.skill-lock.json`,
keeping everything version-controlled in this repo. Agent-specific symlinks (`~/.claude/skills/`,
`~/.cursor/skills/`) are created automatically by the CLI. Set `DISABLE_TELEMETRY=1` to opt out of
anonymous install telemetry (add to `~/.bash_secrets`).

Note: the `firecrawl` skill requires Firecrawl CLI to be installed and authenticated — see
`setup/03-dev-environment.md` (`firecrawl --status`).

**First-time setup — symlink `~/.agents`:**

```bash
ln -sfn ~/projects/agent-box-setup/configs/agents ~/.agents
ln -sfn ~/projects/agent-box-setup/configs/agents ~/agents
# Remove stale/dangling skill links before re-sync.
find ~/.claude/skills ~/.cursor/skills -maxdepth 1 -xtype l -delete
```

**Install all upstream skills:**

```bash
npx skills add anthropics/skills -g -s docx -s frontend-design -s pdf -s webapp-testing -s xlsx -y
npx skills add vercel-labs/agent-skills -g -s vercel-react-best-practices -s web-design-guidelines -y
npx skills add vercel-labs/agent-browser -g -s agent-browser -y
npx skills add obra/superpowers -g -s brainstorming -s verification-before-completion -y
npx skills add wshobson/agents \
  -g -s bash-defensive-patterns -s error-handling-patterns \
  -s react-state-management -s tailwind-design-system -s visual-design-foundations -y
npx skills add DeckardGer/tanstack-agent-skills -g --all -y
npx skills add firecrawl/cli -g -s firecrawl -y
npx skills add alejandrobailo/no-use-effect -g -s no-use-effect -y
npx skills add antfu/skills -g -s pnpm -y
npx skills add jezweb/claude-skills -g -s shadcn-ui -y
npx skills add elastic/agent-skills -g \
  -s elasticsearch-audit -s elasticsearch-authn -s elasticsearch-authz \
  -s elasticsearch-esql -s elasticsearch-file-ingest -s elasticsearch-onboarding \
  -s elasticsearch-security-troubleshooting \
  -y
# kibana-*, cloud-*, security-*, and observability-* skills intentionally excluded:
# kibana-* not needed (no Kibana usage planned)
# cloud-* targets Elastic Cloud SaaS/Serverless (we use ECK self-managed)
# security-* is the Elastic SIEM product, not general ES security
# observability-* (EDOT instrumentation) deferred — see docs/specs/99-backlog.md
```

**Custom skills** (`gg-commit-push`, `markdownlint`, `quarkus`) are not published on skills.sh and
live only in this repo. Symlink them manually:

```bash
mkdir -p ~/.claude/skills ~/.cursor/skills
for skill in gg-commit-push markdownlint quarkus; do
  ln -sfn ~/projects/agent-box-setup/configs/agents/skills/$skill ~/.claude/skills/$skill
  ln -sfn ~/projects/agent-box-setup/configs/agents/skills/$skill ~/.cursor/skills/$skill
done
```

**Note — Quarkus skill**: the upstream `b6k-dev/quarkus-skill` uses a custom directory structure not
compatible with `npx skills add`. Only `SKILL.md` is vendored here; the full reference tree is
intentionally omitted. To update: check `https://github.com/b6k-dev/quarkus-skill` for changes to
`skill/quarkus/SKILL.md` and copy the updated content into `configs/agents/skills/quarkus/SKILL.md`
manually.

**Update all upstream skills:**

```bash
npx skills update
```

**Verify skills:**

```bash
npx skills ls -g
```

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
ls -l ~/.claude/statusline-command.sh && \
ls -l ~/.codex/config.toml && \
echo -e "\n=== Rules Count ===" && \
echo "Claude rules: $(ls ~/.claude/rules/ 2>/dev/null | wc -l)" && \
echo "Cursor rules: $(ls ~/.cursor/rules/ 2>/dev/null | wc -l)" && \
echo -e "\n=== Agent Config Links ===" && \
ls -ld ~/.agents ~/agents && \
echo -e "\n=== Skills Count ===" && \
count_entries() { find "$1" -mindepth 1 -maxdepth 1 ! -name 'AGENTS.md' 2>/dev/null | wc -l; } && \
echo "Claude skills: $(count_entries ~/.claude/skills)" && \
echo "Cursor skills: $(count_entries ~/.cursor/skills)" && \
echo "Agent skills: $(count_entries ~/.agents/skills)"
```

**Next:** Continue to `02-core-tools.md`
