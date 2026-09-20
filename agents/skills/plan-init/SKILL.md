---
name: plan-init
description: One-time setup of _plans/ directory for managing the plans.
  updating a plan.
---

# Plan init

Call it once (in the repo where you keep your plans) and then never call it again. This skill sets
up your directory with the folders required to manage your agents, and a README.md that is the index
of what is next and what is open.

## Layout

```text
_plans/
  README.md
  drafts/
  next/
  open/
  done/
  discarded/
```

- `README.md` — index of the stage descriptions and a `Repository rules` section for rules that apply to this repository only.
- `drafts/` — not ready to queue.
- `next/` — queued. Listed in the README.
- `open/` — in flight. Listed in the README.
- `done/` — finished.
- `discarded/` — abandoned.

## Workflow

1. Target is the current repo root unless the user names another existing directory.
2. Execute this skill's `scripts/init-plans.sh` with that directory. Do not create the tree by hand.
3. If the script reports already initialized, stop. Do not run it again. Do not import leftover
   `plans/`, `_incoming/`, or `incoming/` after that.
4. If the script refuses because `_plans/` exists with a different layout, stop. Do not merge,
   migrate, overwrite, or delete it.
5. On first init, if `plans/`, `_incoming/`, or `incoming/` exist, their contents are moved into
   `_plans/drafts/` and those source directories are removed. Duplicate names are deduped by the
   script: the first keeps its name, later ones get a unix-milliseconds stamp attached (`note.md` →
   `note-1730000000123.md`). Do not copy. Do not overwrite.
6. Report the created tree and anything moved into drafts.

## Completion

Done when `_plans/` matches the layout above, `_plans/README.md` is the next/open index with its
stage descriptions and an empty `Repository rules` section, and the five stage directories exist.
Files that lived in `plans/`, `_incoming/`, or `incoming/` now live in
`_plans/drafts/`, and those source directories are gone. No extra top-level files. No placeholder
plans.
