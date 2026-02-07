# 01 - Agent Setup

## Agent Installation

### Claude

Claude should already be installed. If not, install [Claude](https://code.claude.com/docs/en/setup)

```bash
curl -fsSL https://claude.ai/install.sh | bash
```

Configure [privacy settings](https://claude.ai/settings/data-privacy-controls) to disallow chat / prompt usage.

Run `claude` and followed the authentication prompts.

### Cursor CLI

As per the [installation instructions](https://cursor.com/docs/cli/installation)

```bash
curl https://cursor.com/install -fsS | bash
```

Check if the agent can be called using `agent`, otherwise you may need to add `.local/bin` to your PATH.

## Global Agent Rule File

Both Claude Code and Cursor read `~/AGENTS.md` automatically. Claude Code also needs `~/CLAUDE.md`.

Source: `configs/agents/AGENTS.md`
Destination: `~/AGENTS.md` (with `~/CLAUDE.md` symlink)

```bash
ln -sf ~/projects/dave-box-setup/configs/agents/AGENTS.md ~/AGENTS.md
ln -sf ~/AGENTS.md ~/CLAUDE.md
```

## Agent-specific settings files

### Claude Code Settings

Current settings:

| Setting | Value | Description |
| ------- | ----- | ----------- |
| `model` | `opusplan` | Opus for planning, Sonnet for execution |
| `permissions.defaultMode` | `bypassPermissions` | YOLO mode - (no confirmation prompts) |
| `spinnerVerbs` | `["Working"]` | Simplified spinner text |

```bash
ln -sf ~/projects/dave-box-setup/configs/agents/claude/settings.json ~/.claude/settings.json
```

### Cursor CLI Settings

As per the [documentation for Cursor CLI](https://cursor.com/docs/cli/reference/configuration), settings are stored in `~/.cursor/cli-config.json`. We don't touch these settings for now, as the CLI adds many of its own props to it.

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
ln -sf ~/projects/dave-box-setup/configs/agents/user-rules/*.mdc ~/.claude/rules/
ln -sf ~/projects/dave-box-setup/configs/agents/user-rules/*.md ~/.claude/rules/
```

### Cursor CLI user-level rules

Rules as a means to manage context are [described here](https://cursor.com/blog/agent-best-practices#rules-static-context-for-your-project)

As per the [documentation](https://cursor.com/docs/context/rules#rule-file-format), rules should be in the home dir of the user in the `.cursor/rules` directory.

```bash
mkdir -p ~/.cursor/rules
ln -sf ~/projects/dave-box-setup/configs/agents/user-rules/*.mdc ~/.cursor/rules/
```

## LATER: Skills / Tools

Read the [official documentation](https://agentskills.io/what-are-skills) first.

Then check [skills.sh](https://skills.sh/)

Vercel is saying [skills don't really work, yet](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)

For Claude, read the [documentation here](https://code.claude.com/docs/en/skills)
For Cursor, read the [documentation here](https://agentskills.io/what-are-skills)

[React rules](https://vercel.com/blog/introducing-react-best-practices)
=> npx add-skill vercel-labs/agent-skills
=> try in frontend

Codex take on [skills/evals](https://developers.openai.com/blog/eval-skills)

**Next:** Continue to `02-core-tools.md`
