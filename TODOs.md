# TODOs

There are things we want to do project-level here, fold them out into another repo. They will ofc depend
on a properly set up box.

- Get a proper terminal (Ghostty)
- try browser automation in all agents
- put docs in condensed form into [AGENTS.md](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)
- Claude [status line](https://code.claude.com/docs/en/statusline)
- [Github and Bugbot integration](https://cursor.com/docs/integrations/github)
- Superpowers plugin removed. `brainstorming` + `verification-before-completion` skills (from
  [obra/superpowers](https://github.com/obra/superpowers)) kept for now — revisit whether an
  ADLC-aligned workflow can replace them. See ADLC in the website project:
  `website/src/pages/ai/aidlc.mdx` (route `/ai/aidlc`).

<https://www.youtube.com/watch?v=I9-tdhxiH7w> <https://www.youtube.com/watch?v=rcRS8-7OgBo>
<https://www.youtube.com/watch?v=P60LqQg1RH8>

[More skills](https://code.claude.com/docs/en/skills) and
[https://simonwillison.net/2025/Oct/16/claude-skills/](https://simonwillison.net/2025/Oct/16/claude-skills/)
[LSP / Code intelligence plugins](https://code.claude.com/docs/en/discover-plugins#code-intelligence)

- there should be rules/skills for quarkus, tanstack start, scripts for playwright etc.

Also look at jeffrey emmanuel skills portfolio

## project setup

Some of the steps in here are actually only relevant for certain types of projects, e.g. you only
need sdkman if you are working on a JAVA project. Break out these parts as well as the relevant
skills / tools / rules into packages.

This is not only about toolchains — most of `configs/agents/skills/` is project-level, not
box-level. Right now everything is installed globally so every project gets everything, which is the
wrong default: a Quarkus project does not need `tanstack-*`, an infra/docs repo does not need
`shadcn-ui`. Candidate split:

- **Always-on (box-level)**: `markdownlint`, `gg-commit-push`, `brainstorming`, `grill-me`,
  `verification-before-completion`, `firecrawl`, `agent-browser`.
- **Per project type**: tanstack/react/tailwind/shadcn (web), `quarkus`/`pnpm` (toolchain),
  `elasticsearch-*` (ES work), `docx`/`xlsx`/`pdf` (document work).

Until that split exists, note the scope in `README.md` and keep installing globally.

## etc

[Subagents](https://code.claude.com/docs/en/sub-agents)
[Check workflow here](https://code.claude.com/docs/en/costs#work-efficiently-on-complex-tasks)

### Codex

[simonwillison openai-skills](https://simonwillison.net/2025/Dec/12/openai-skills/)
