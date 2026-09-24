# Agents

Install Claude Code, Codex, Cursor CLI, and Pi on both host and VM. The host completion gate
authenticates all four. The VM baseline installs and configures all four without authentication;
guest logins are a later explicit credential phase. Host and VM agents use the repo-managed YOLO
settings.

These are CLI installs, not desktop application packages:

- Claude Code is installed by Anthropic's native user installer under `~/.local/`.
- Codex and Pi are installed from the user-owned npm prefix under `~/.npm-global/`.
- Cursor CLI is installed by Cursor's user installer under `~/.local/`.

The tracked files in this repo are the source of truth for agent
configuration; do not introduce host-local replacements.

## Order

1. [Global rule file](#global-rule-file)
2. [Claude Code](claude/README.md)
3. [Codex](codex/README.md)
4. [Cursor CLI](cursor/README.md)
5. [Pi](pi/README.md)
6. [Skills](#skills)
7. [Caveman](#caveman)

## Global rule file

```bash
ln -sfn ~/projects/agent-box-setup/agents/AGENTS.md ~/AGENTS.md
ln -sfn ~/AGENTS.md ~/CLAUDE.md
```

## Skills

The repository's `agents/skills/` directory is the global skill index. `~/.agents/skills` is the
canonical local skill path for Codex, Cursor, and Pi. Claude Code reads only `~/.claude/skills`; as
of v2.1.278 it does not support the canonical path, so it needs a compatibility link. Both agent
homes reach the index through a single directory-level symlink:

```bash
ln -sfn ~/projects/agent-box-setup/agents ~/.agents
mkdir -p ~/.claude ~/.pi/agent
ln -sfn ~/projects/agent-box-setup/agents/skills ~/.claude/skills
ln -sfn ~/projects/agent-box-setup/agents/AGENTS.md ~/.pi/agent/AGENTS.md
```

Link the directory, never the individual skills. BB and Codex reject a skill whose own root path is
a symlink:

```text
Root path "/home/dave/.agents/skills/<skill>" must not be a symlink
```

Such a skill still appears in `claude` and `cursor-agent`, which resolve symlinks through the
kernel, so the breakage is silent and partial. Linking one level up keeps every skill root a real
directory, so all four agents and the BB skills panel see the same index.

The invariant is therefore: `~/.agents` and `~/.claude/skills` are symlinks, and nothing inside
`agents/skills/` is. The `agent-config` module checks both halves after linking.

Claude Code writes claude.ai account-synced skills into `~/.claude/skills/synced/`, so they land in
`agents/skills/synced/`. That path is gitignored, and `audit-skills.sh` skips it because it holds
skills rather than being one.

Install upstream skills into the source directory:

```bash
npx skills add anthropics/skills -g -s docx -s frontend-design -s pdf -s xlsx -y
npx skills add vercel-labs/agent-skills -g -s vercel-react-best-practices -s web-design-guidelines -y
npx skills add vercel-labs/agent-browser -g -s agent-browser -y
npx skills add obra/superpowers -g -s verification-before-completion -y
npx skills add wshobson/agents -g -s bash-defensive-patterns -s error-handling-patterns \
  -s react-state-management -s tailwind-design-system -s visual-design-foundations -y
npx skills add DeckardGer/tanstack-agent-skills -g --all -y
npx skills add firecrawl/cli -g -s firecrawl -y
npx skills add alejandrobailo/no-use-effect -g -s no-use-effect -y
npx skills add antfu/skills -g -s pnpm -y
npx skills add jezweb/claude-skills -g -s shadcn-ui -y
npx skills add elastic/agent-skills -g \
  -s elasticsearch-audit -s elasticsearch-authn -s elasticsearch-authz \
  -s elasticsearch-esql -s elasticsearch-file-ingest -s elasticsearch-onboarding \
  -s elasticsearch-security-troubleshooting -y
```

Audit and update upstream skills:

```bash
cd ~/projects/agent-box-setup
./audit-skills.sh
npx skills update
```

## Caveman

Caveman lives in `agents/skills/` with the rest of the shared skills. Codex, Cursor, and Pi use
`~/.agents/skills`; Claude Code uses the compatibility links above. Codex and Cursor still use their
hook files; they do not need a separate checkout of `JuliusBrussee/caveman`.

Configure the Claude Code plugin and the Codex/Cursor hooks in the individual agent guides.

## Verification

```bash
claude --version
codex --version
agent --version
pi --version
cd ~/projects/agent-box-setup
./modules/verify-box.sh xhost --operational  # host completion
./modules/verify-box.sh xagt --bootstrap     # guest, before provider login
```

## Checklist

- [ ] Claude Code, Codex, Cursor CLI, and Pi are installed on both targets
- [ ] repo-managed YOLO settings are applied on both targets
- [ ] host agents are authenticated for the host completion gate
- [ ] guest agents are authenticated only after `clean-guest`, when explicitly wanted
- [ ] global instructions are linked for Claude Code, Codex, and Pi
- [ ] shared skills resolve through `~/.agents/skills`, with Claude Code compatibility links
- [ ] Codex and Cursor Caveman hooks are linked
- [ ] the target's profiled verification command completes
