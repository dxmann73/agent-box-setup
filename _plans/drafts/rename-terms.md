# Rename `babysit`/`sit` and `overlay` terms

- created: 2026-09-21
- priority: p3 (low) — wording preference, no urgency signal in the text
- branch: main

also add a plan regarding the wording.

## Terms currently in use

- `babysit` — used in `AGENTS.md` and skill descriptions (e.g. `bb-sudo-terminal`) for a
  supervised sudo/host-attend session.
- `sit` — catalog column header in `modules/README.md` (values `-` unattended, `boot`
  bootstrap, `iso` guest, `gcred` guest credentials, `login` login cluster). Present in every
  module's `README.md` catalog row.
- `overlay` — used across `README.md`, `START-HERE.md`, `AGENTS.md`, `modules/README.md`, and
  many module docs. Refers to the private deployment repo (`dave.box-setup`) that layers on top
  of the public `agent-box-setup` base.
- `daily hosts` - the hosts are not "daily" but just different host machines

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
