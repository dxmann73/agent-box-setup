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

Docs state present intent, not history — git keeps history. Applies to every doc regardless of
format: plans, PRDs, SDDs, specs, READMEs. When revising, rewrite so it reads as written today:
delete instead of annotating ("superseded by", "previously we said", strikethrough), and drop
rejected options and out-of-scope items unless the rejection is the doc's point.

Exception: docs whose purpose is a record over time — CHANGELOGs, ADR status, migration guides.
