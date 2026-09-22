# Rename `babysit`/`sit` and `overlay` terms

- created: 2026-09-21
- priority: p3 (low) — wording preference, no urgency signal in the text
- branch: main

also add a plan regarding the wording. I want to use another term for babysit/sit and also for
overlay.

## Terms currently in use

- `babysit` — used in `AGENTS.md` and skill descriptions (e.g. `bb-sudo-terminal`) for a
  supervised sudo/host-attend session.
- `sit` — catalog column header in `modules/README.md` (values `-` unattended, `boot`
  bootstrap, `iso` guest, `gcred` guest credentials, `login` login cluster). Present in every
  module's `README.md` catalog row.
- `overlay` — used across `README.md`, `START-HERE.md`, `AGENTS.md`, `modules/README.md`, and
  many module docs. Refers to the private deployment repo (`dave.box-setup`) that layers on top
  of the public `agent-box-setup` base.

## Work to do (not yet designed)

1. Pick a replacement for `babysit`/`sit`. Candidates to weigh: `attend` (`att`),
   `supervise` (`sup`), `stage` (`stg`), `phase` (`phs`), `session` (`ses`).
   Constraint: the catalog column is 3-4 chars wide; the noun must fit.
2. Pick a replacement for `overlay`. Candidates to weigh: `deployment`, `profile`, `variant`,
   `personalization`, `personal-layer`, `flavor`.
3. Confirm both replacements read well in a full sentence (`babysit: ask the user…` and
   `the dave.box overlay` are the current shapes) — not just in isolation.
4. Sweep both repos (`agent-box-setup` and `dave.box-setup`) — the term lives in both.
5. Do the rename in one commit per term, not mixed, to keep the diff reviewable.
6. Update the catalog column header + every module's row when `sit` is renamed. Keep the
   value shorthand (`-`, `boot`, `iso`, `gcred`, `login`) unless a value should also change.
7. Consider whether `sit` values themselves need updating (`iso`, `gcred`, `login` all read
   fine independent of the header name).

## Related

(none — scan of `_plans/drafts/`, `_plans/next/`, `_plans/open/` found no naming or wording
plan)

## Observations

- `overlay` appears in ~25 files across the repo (README.md, START-HERE.md, AGENTS.md,
  modules/README.md, many module READMEs).
- `sit` appears as the catalog column header in every module README and in `modules/README.md`
  multiple times — rename is a mechanical but wide sweep.
- `babysit` appears in `AGENTS.md` and in skill descriptions such as `bb-sudo-terminal` (skill
  lives under `~/.claude/`, not this repo — may not be in scope for a repo rename).
- The private overlay repo `~/projects/dave.box-setup/` also uses these terms; a full rename
  should be coordinated across both repos in one pass.
- Repo is clean on branch `main`.

---

Also see `_plans/README.md` and the project `README.md` for any rules that apply.
