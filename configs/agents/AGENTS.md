# Agent Rules

## General

- reply in telegraph style, avoid filler language, less lines and headings
- avoid emphasis, icons and symbols if not needed
- Before writing code, first explore the project structure
- My Workspace where you can find projects: `~/projects`
- My Github `https://github.com/dxmann73`
- "Do a sync run" means:
  - check the current project against `agent-box-setup` for drift
  - verify linked rules/skills are present
  - align AGENTS/README references
  - report what changed
- "add general rule" or "add global rule" means edit `~/AGENTS.md`
- "add project rule" means edit project-root AGENTS.md
- "add user rule" means create a new rule file in `agent-box-setup` under `user-rules` in mdc format
- Editor: `cursor <path>`.
- Web: use Firecrawl skill, search early; prefer recent sources e.g. 2025–2026
- For any web search/research task, first check whether Firecrawl can be used and use it when
  available.
- Before adding any new dependency, run a GitHub health check and report the results to the user.
  The report must include number of contributors, recent contribution activity, commit frequency,
  open issues, latest release date, and license status.
- If unsure, read more code; if still stuck, ask w/ short options.
- If you hit unexpected concurrent changes:
  - assume another agent is working in parallel
  - keep going and keep your edits focused
  - stop and ask user only if there is a direct conflict/blocker.
  - Don’t delete/rename unexpected stuff; stop + ask.
- gg means commit and push, there is a skill for it
- Shell aliases must always be added/updated in `~/.bash_aliases`, never in `~/.bashrc`.
- When in plan mode, ask clarifying questions if you're not sure what to do.
  Try to provide alternative approaches.

## Planning Artifacts

- When creating or updating implementation/design plans, store them in `<repo-root>/.plans/`.
- Plan filenames must be date-prefixed: `YYYY-MM-DD-<topic>-plan.md`.
- Do not store plan artifacts in personal or ad-hoc folders outside the repository.
- If a plan includes UX changes, include or update corresponding user-facing documentation references
  in the same plan.
- If `.plans/` does not exist, create it in the repository root.

## Markdown

- when creating or changing markdown files, use the `markdownlint` skill
- line length is 120 per default. Reflow lines at that length if not given in `.markdownlint.json`

## git / github

- Keep new repos private by default
- Commits: Conventional Commits (`feat|fix|refactor|build|ci|chore|docs|style|perf|test`).
- Safe by default: `git status/diff/log`. Push only when user asks.
- Destructive operations and commands are forbidden unless explicitly allowed
  e.g. `reset --hard`, `clean`, `restore`, `rm`
