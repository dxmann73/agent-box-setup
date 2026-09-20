---
name: plan-next
description: Review _plans/drafts/ and recommend the top five draft plans that are
  ready and logical to work on next.
---

# Plan next

Pick the next likely work item from a ranked choice set of draft plans.

This skill reads plans and project direction only.

## Scope

- Target is the current workspace unless the user names another existing repository.
- Read `_plans/drafts/` completely.
- Read context from `_plans/README.md`, root `ROADMAP.md`, `VISION.md`, and `README.md` when they
  exist.
- Read filenames and titles in `_plans/next/`, `_plans/open/`, `_plans/done/`, and
  `_plans/discarded/` to detect sequencing, duplicates, active work, or already-finished work.
- Do not read other sources unless the user explicitly names them.

## Ranking

Balance the following signals:

- Explicit priority in the draft, especially `p0` or `p1`, with believable evidence.
- Direct alignment with `_plans/README.md`, `ROADMAP.md`, `VISION.md`, or root `README.md`.
- Unblocks other drafts or a roadmap item.
- Fits the current repository and its stated architecture or rules.

Down-rank or exclude:

- Depends on another draft that should happen first.
- Duplicates something in `_plans/next/`, `_plans/open/`, or `_plans/done/`.
- Conflicts with repository rules, scope boundaries, or active work.
- Is explicitly deferred, exploratory, or "someday" unless few other candidates exist.

## Output

Return a pick list of up to five drafts, sorted best first. If fewer than five look ready, return
only the ready set and mention the count. For each item include:

- Rank number.
- Draft path.
- Title.
- Priority, if the draft states one.
- Why it is a logical next item.
- Readiness notes: what makes it executable now, plus any blocker or assumption.

End by asking the user to choose by rank, title, or path. Do not invoke another skill until the user
chooses.

## No Ready Drafts

If no draft is ready, say so plainly. List the closest candidates with the missing decision or
context needed to make each one ready. Do not invent missing requirements to force a pick.

## Handoff

After the user chooses one item, invoke `plan-write` with the selected draft if that skill is
available. If `plan-write` is not available yet, report the selected draft and say the write skill is
not installed or not designed yet.
