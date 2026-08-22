# Agents

Agent CLIs, their configuration, and the shared skill set. Installed identically on host and VM;
`machines/common/` links here from its setup flow.

## Layout

| Path | Contents |
| ---- | -------- |
| [claude/](claude/README.md) | Claude Code — install, `settings.json`, statusline, caveman |
| [cursor/](cursor/README.md) | Cursor CLI Agent — install, `cli-config.json` reference, caveman |
| [codex/](codex/README.md) | Codex CLI — install, `config.toml`, caveman |
| `skills/` | Skill set, single source of truth (see [Skills](#skills)) |
| `AGENTS.md` | Global agent rule file, symlinked to `~/AGENTS.md` |
| `.skill-lock.json` | Lock file written by `npx skills` |

## Order

1. Global agent rule file (below)
2. [claude/](claude/README.md)
3. [cursor/](cursor/README.md)
4. [codex/](codex/README.md)
5. [Skills](#skills)
6. [Complete verification](#complete-verification)

## Global Agent Rule File

Both Claude Code and Cursor read `~/AGENTS.md` automatically. Claude Code also needs `~/CLAUDE.md`.

Source: `agents/AGENTS.md` Destination: `~/AGENTS.md` (with `~/CLAUDE.md` symlink)

```bash
ln -sf ~/projects/agent-box-setup/agents/AGENTS.md ~/AGENTS.md
ln -sf ~/AGENTS.md ~/CLAUDE.md
```

**Verify symlinks:**

```bash
ls -l ~/AGENTS.md ~/CLAUDE.md
```

Both should point to `~/projects/agent-box-setup/agents/AGENTS.md`

## Rules, Skills, MCP, Hooks

Leerob video
[Agent Skills, Rules, Subagents: Explained!](https://www.youtube.com/watch?v=L_p5GxGSB_I)

There is no user-level rules directory on this box. Global instructions live in `~/AGENTS.md`
(`~/CLAUDE.md` symlink, see "Global Agent Rule File"); per-project instructions live in the
project-root `AGENTS.md` with a `CLAUDE.md` symlink. Codex reads `~/AGENTS.md`, Claude Code reads
`~/CLAUDE.md`, and the [Cursor CLI](https://cursor.com/docs/cli/using#rules) reads project-root
`AGENTS.md`/`CLAUDE.md` plus `.cursor/rules` inside a project. Cursor "User Rules" are free-text
preferences set in **Customize → Rules**, not files.

### MCP servers

MCP servers stay **off** on both machines. Skills and hooks cover what this box needs, and every
enabled server adds tool definitions to each prompt plus a process that talks to the network.
Confirm after setting up an agent — neither is scriptable, both are one-off checks in a running
session:

- `/mcp` in Claude Code lists the configured servers; the list should be empty.
- `claude config list` shows the effective agent configuration.

## Skills

[Official documentation](https://agentskills.io/what-are-skills). For further reading, see also the
Codex take on [skills/evals](https://developers.openai.com/blog/eval-skills).

Skills are managed via the [skills CLI](https://github.com/vercel-labs/skills) (`npx skills`).
Because `~/.agents` is symlinked to `agents/`, a global install (`-g`) writes skill files
directly into `agents/skills/` and the lock file into `agents/.skill-lock.json`,
keeping everything version-controlled in this repo. Agent-specific symlinks (`~/.claude/skills/`,
`~/.cursor/skills/`) are often created automatically by the CLI, but do not rely on that alone:
finish with the directory-driven sync below so every box matches the repo exactly. Set
`DISABLE_TELEMETRY=1` to opt out of anonymous install telemetry (add to `~/.bash_secrets`).

Note: the `firecrawl` skill requires Firecrawl CLI to be installed and authenticated — see
`machines/common/03-dev-environment.md` (`firecrawl --status`).

**First-time setup — symlink `~/.agents`:**

```bash
ln -sfn ~/projects/agent-box-setup/agents ~/.agents
ln -sfn ~/projects/agent-box-setup/agents ~/agents
# Remove stale/dangling skill links before re-sync.
find ~/.claude/skills ~/.cursor/skills -maxdepth 1 -xtype l -delete
```

**Install all upstream skills:**

```bash
npx skills add anthropics/skills -g -s docx -s frontend-design -s pdf -s xlsx -y
npx skills add vercel-labs/agent-skills -g -s vercel-react-best-practices -s web-design-guidelines -y
npx skills add vercel-labs/agent-browser -g -s agent-browser -y
npx skills add obra/superpowers -g -s verification-before-completion -y
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

**Custom / repo-owned skills** (for example `gg-commit-push`, `markdownlint`, `quarkus`,
`brainstorming`, `grill-me`, `new-project`, `sync-repo-setup`) are not managed by `npx skills add`
or `npx skills update` (no lockfile entry).
Some upstream-managed skills may also fail to create or refresh agent-specific symlinks on an older
box. Normalize all skill links from the repo after installs or updates:

```bash
mkdir -p ~/.claude/skills ~/.cursor/skills
find ~/.claude/skills ~/.cursor/skills -maxdepth 1 -xtype l -delete
find ~/projects/agent-box-setup/agents/skills -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' skill_dir; do
  skill_name="$(basename "$skill_dir")"
  ln -sfn "$skill_dir" ~/.claude/skills/"$skill_name"
  ln -sfn "$skill_dir" ~/.cursor/skills/"$skill_name"
done
```

**Brainstorming** — Originally derived from [obra/superpowers](https://github.com/obra/superpowers)
(`skills/brainstorming`); content is maintained here so upstream changes do not overwrite local
edits.

**Grill-me** — Vendored from [mattpocock/skills](https://github.com/mattpocock/skills)
(`skills/grill-me`); not on skills.sh, so it is copied in and maintained here. Pairs with
`brainstorming`: brainstorm to open up options, grill-me to stress-test the chosen plan before
implementation.

**Note — Quarkus skill**: the upstream `b6k-dev/quarkus-skill` uses a custom directory structure not
compatible with `npx skills add`. Only `SKILL.md` is vendored here; the full reference tree is
intentionally omitted. To update: check `https://github.com/b6k-dev/quarkus-skill` for changes to
`skill/quarkus/SKILL.md` and copy the updated content into `agents/skills/quarkus/SKILL.md`
manually.

**Update all upstream skills:**

```bash
npx skills update
```

**Verify skills:**

```bash
npx skills ls -g
```

## Caveman

[Caveman](https://github.com/JuliusBrussee/caveman) cuts ~75% of output tokens, keeps technical
accuracy. Clone the repo once; each agent's own README covers its wiring.

```bash
git clone https://github.com/JuliusBrussee/caveman ~/projects/caveman
```

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
rg -n "^[[:space:]]*hooks[[:space:]]*=[[:space:]]*true$" ~/.codex/config.toml && \
ls -l ~/.codex/hooks.json && \
ls -l ~/.cursor/hooks.json ~/.cursor/hooks && \
echo -e "\n=== Agent Config Links ===" && \
ls -ld ~/.agents ~/agents && \
echo -e "\n=== Skills Count ===" && \
count_entries() { find "$1" -mindepth 1 -maxdepth 1 ! -name 'AGENTS.md' 2>/dev/null | wc -l; } && \
echo "Claude skills: $(count_entries ~/.claude/skills)" && \
echo "Cursor skills: $(count_entries ~/.cursor/skills)" && \
echo "Agent skills: $(count_entries ~/.agents/skills)"
```

**Next:** back to `machines/common/02-core-tools.md`
