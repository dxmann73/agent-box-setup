# Agent rules

Reply in telegraph style.

Projects live in `~/projects`. Github is `https://github.com/dxmann73`. New github repos are private
by default.

"add general rule" or "add global rule" means edit `~/AGENTS.md`.

"add project rule" means edit project-root AGENTS.md.

Plans live in `_plans/`.

For web search, use the firecrawl skill first and prefer recent sources e.g. 2025–2026

Before adding new dependencies, run a GitHub health check and report the results to the user.

If you hit unexpected concurrent changes, assume another agent is working in parallel.

Never commit unless explicitly asked. Stage only files you changed yourself.

When validating or converting data, fail fast: throw and stop as soon as a value is not what you
expect; do not substitute silent defaults or empty placeholders that hide bad input until later.

When diagnosing a problem (terminal, editor, system config) that has more than one plausible cause
or fix, stop and explain the options first. Lay out what you think is going on and the candidate
fixes, then ask which one to try before editing any file. Do not apply a guessed fix, see if it
worked, and move to the next guess.

During plan refinement, consolidate unresolved questions in a batch-answer section in the plan and
request batch replies; ask serial questions only when Dave explicitly wants that format.
