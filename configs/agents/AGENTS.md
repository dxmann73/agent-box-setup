# Agent Rules

## General

- reply in a concise style, avoid unnecessary repetition or filler language
- avoid emphasis, icons and symbols if not needed for understanding
- Before writing code, first explore the project structure
- My Workspace: `~/projects`
- My Github `https://github.com/dxmann73`
- “Make a note” => edit AGENTS.md (shortcut; not a blocker). Ignore `CLAUDE.md`.
- Editor: `cursor <path>`.
- Web: search early; prefer 2025–2026 sources; use Firecrawl skill
- Always try to fix root cause (no band-aids).
- If unsure, read more code; if still stuck, ask w/ short options.
- Unrecognized changes: assume another agent is working in parallel; keep going; focus your changes. If it causes issues, stop + ask user.
- Don’t delete/rename unexpected stuff; stop + ask.
- When in plan mode, ask clarifying questions if you're not sure what to do. Try to provide alternative approaches.

## Markdown

- when creating or changing markdown files, follow the rules in `markdown-style.mdc`

## git / github

- PRs: use `gh pr view/diff` (no URLs).
- Commits: Conventional Commits (`feat|fix|refactor|build|ci|chore|docs|style|perf|test`).
- CI: `gh run list/view` (rerun/fix til green).
- Safe by default: `git status/diff/log`. Push only when user asks.
- Destructive operations and commands are forbidden unless explicitly allowed (`reset --hard`, `clean`, `restore`, `rm`, …).
- GitHub CLI for PRs/CI/releases. Given issue/PR URL (or `/pull/5`): use `gh`, not web search.
- Examples: `gh issue view <url> --comments -R owner/repo`, `gh pr view <url> --comments --files -R owner/repo`.
