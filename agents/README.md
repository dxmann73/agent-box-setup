# Agents

Install Claude Code, Codex, Cursor CLI, and Pi on both host and VM. The VM bootstrap installs Claude
Code first; this guide installs the complete agent set during the common toolchain stage.

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

The repository's `agents/skills/` directory is the source of truth. Link it into every agent:

```bash
ln -sfn ~/projects/agent-box-setup/agents ~/.agents
ln -sfn ~/projects/agent-box-setup/agents ~/agents
mkdir -p ~/.claude/skills ~/.cursor/skills ~/.codex/skills ~/.pi/agent
find ~/.claude/skills ~/.cursor/skills ~/.codex/skills -maxdepth 1 -xtype l -delete
find ~/projects/agent-box-setup/agents/skills -mindepth 1 -maxdepth 1 -type d -print0 |
  while IFS= read -r -d '' skill_dir; do
    skill_name="$(basename "$skill_dir")"
    ln -sfn "$skill_dir" ~/.claude/skills/"$skill_name"
    ln -sfn "$skill_dir" ~/.cursor/skills/"$skill_name"
    ln -sfn "$skill_dir" ~/.codex/skills/"$skill_name"
  done
ln -sfn ~/projects/agent-box-setup/agents/AGENTS.md ~/.pi/agent/AGENTS.md
ln -sfn ~/projects/agent-box-setup/agents/skills ~/.pi/agent/skills
```

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

Caveman lives in `agents/skills/` with the rest of the shared skills. Codex and Cursor use the
repo-managed skill symlinks plus their hook files; they do not need a separate checkout of
`JuliusBrussee/caveman`.

Configure the Claude Code plugin and the Codex/Cursor hooks in the individual agent guides.

## Verification

```bash
claude --version
codex --version
agent --version
pi --version
cd ~/projects/agent-box-setup
./verify-setup.sh
```

## Checklist

- [ ] Claude Code, Codex, Cursor CLI, and Pi are installed and authenticated
- [ ] global instructions are linked for Claude Code, Codex, and Pi
- [ ] shared skills are linked for all four agents
- [ ] Codex and Cursor Caveman hooks are linked
- [ ] `./verify-setup.sh` completes for the target machine
