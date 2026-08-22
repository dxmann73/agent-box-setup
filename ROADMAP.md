# box setup roadmap

## Repo prep / cleanup

- change setup instructions to use vs code instead of cursor.
- check all settings and how they differ, keep list of them, plan AND TEST vs code settings sync
- check cursor subscription model / renewal.
- retire voice tooling setup (separate commit)
- AGENTS, BOOTSTRAP, README, SETUP are all massively outdated
- Rename repo to agent-setup
- tie up all loose ends (desktops both xmg an blade!) and push/sync all repos

## setup

- do the whole setup once, by hand

## Skills / Agents

- put docs in condensed form into [AGENTS.md](https://vercel.com/blog/agents-md-outperforms-skills-in-our-agent-evals)
- Claude [status line](https://code.claude.com/docs/en/statusline)
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

Look at jeffrey emmanuel skills portfolio
[Check workflow here](https://code.claude.com/docs/en/costs#work-efficiently-on-complex-tasks)
[simonwillison openai-skills](https://simonwillison.net/2025/Dec/12/openai-skills/)
