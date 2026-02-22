# Agent Rules

## General

- reply in a concise style, avoid unnecessary repetition or filler language
- avoid emphasis, icons and symbols if not needed for understanding
- Before writing code, first explore the project structure
- My Workspace where you can find projects: `~/projects`
- My Github `https://github.com/dxmann73`
- "general rule" => edit `~/AGENTS.md`
- "Make a note" => edit project-root AGENTS.md. Ignore `CLAUDE.md`
- "add a rule" => create a new rule file in agent-box-setup under `user-rules` in mdc format, check if this is visible in the cwd
- Editor: `cursor <path>`.
- Web: search early; prefer 2025–2026 sources; use Firecrawl skill
- Always try to fix root cause (no band-aids).
- Before adding any new dependency, run a GitHub health check and report the results to the user. The report must include number of contributors, recent contribution activity, commit frequency, open issues, latest release date, and license status.
- If unsure, read more code; if still stuck, ask w/ short options.
- Unrecognized changes: assume another agent is working in parallel; keep going; focus your changes. If it causes issues, stop + ask user.
- Don’t delete/rename unexpected stuff; stop + ask.
- When in plan mode, ask clarifying questions if you're not sure what to do. Try to provide alternative approaches.

## Markdown

- when creating or changing markdown files, follow the rules in `markdown-style.mdc`

## git / github

- Keep new repos private by default
- PRs: use `gh pr view/diff` (no URLs).
- Commits: Conventional Commits (`feat|fix|refactor|build|ci|chore|docs|style|perf|test`).
- CI: `gh run list/view` (rerun/fix til green).
- Safe by default: `git status/diff/log`. Push only when user asks.
- Destructive operations and commands are forbidden unless explicitly allowed (`reset --hard`, `clean`, `restore`, `rm`, …).
- GitHub CLI for PRs/CI/releases. Given issue/PR URL (or `/pull/5`): use `gh`, not web search.
- Examples: `gh issue view <url> --comments -R owner/repo`, `gh pr view <url> --comments --files -R owner/repo`.
