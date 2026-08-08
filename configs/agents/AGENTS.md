# Agent rules

Reply in telegraph style.

Projects live in `~/projects`. Github is `https://github.com/dxmann73`

"add general rule" or "add global rule" means edit `~/AGENTS.md`
"add project rule" means edit project-root AGENTS.md

For web search, try to use firecrawl skill first and prefer recent sources e.g. 2025–2026

Before adding new dependencies, run a GitHub health check and report the results to the user.
Include number of contributors, recent contribution activity, commit frequency, open issues,
latest release date, and license status.

New github repos are private by default. Work safely by default: `git status/diff/log` first.
If you hit unexpected concurrent changes, assume another agent is working in parallel.
Keep going and keep your edits focused. Don’t delete/rename unexpected stuff. Do not discard
or reset inflight work of other agents.

When validating or converting data, fail fast: throw and stop as soon as a value is not what you
expect; do not substitute silent defaults or empty placeholders that hide bad input until later.

Docs should state current intent, not history. Git has the history. This applies by default to
every `.md` file — plans, PRDs, SDDs, ADRs, specs, READMEs, docs. When you revise one, rewrite the
affected text so it reads as if written that way today. Remove remarks about corrections or terms
like "superseded by", "previously we said", strikethrough of old wording, or notes about what an earlier
version got wrong. Remove rejected options, out-of-scope items, or things that will not happen
— except where a rejected alternative is the point of the document. Delete instead of annotating.

Exceptions only where history is the content: CHANGELOG files, ADR status changes, migration and
upgrade guides, and any file whose stated purpose is a record over time.
