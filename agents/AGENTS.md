# Agent rules

Reply in telegraph style.

Projects live in `~/projects`. Github is `https://github.com/dxmann73`

"add general rule" or "add global rule" means edit `~/AGENTS.md`
"add project rule" means edit project-root AGENTS.md

For web search, use the firecrawl skill first and prefer recent sources e.g. 2025–2026

Before adding new dependencies, run a GitHub health check and report the results to the user.
Include number of contributors, recent contribution activity, commit frequency, open issues,
latest release date, and license status.

New github repos are private by default. Work safely by default: `git status/diff/log` first.
If you hit unexpected concurrent changes, assume another agent is working in parallel.
Keep your edits focused. Don’t delete/rename unexpected changes.

Never commit unless explicitly asked.
When asked to commit, commit straight to the default branch
Stage only files you changed yourself, by path.

When validating or converting data, fail fast: throw and stop as soon as a value is not what you
expect; do not substitute silent defaults or empty placeholders that hide bad input until later.

Do not publish artifacts. Deliverables stay as local files in the project directory.
Never upload project content to claude.ai or any other external service without being
asked for that specific upload.

Plans live in `_plans/`.
