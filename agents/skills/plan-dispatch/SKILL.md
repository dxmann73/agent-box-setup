---
name: plan-dispatch
description: Move a refined plan from _plans/next/ to _plans/open/ when it is
  ready for active implementation.
---

# Plan dispatch

Move one refined plan from `_plans/next/` to `_plans/open/` when implementation is starting.

This skill dispatches work. It does not implement the plan.

## Inputs

The user may provide a path, title, or rank from `_plans/next/`. If the selected plan is ambiguous,
ask which plan they mean.

## Sources

Read `_plans/README.md` first; it is the source of truth for plan stages, readiness, and repository
rules. Then read the selected plan completely and inspect only the repository context needed to
decide whether the plan is ready to dispatch.

## Readiness Check

Before moving the plan to `open/`, confirm it has:

- clear goal and non-goals
- no blocking open questions
- implementation outline
- acceptance criteria
- verification commands or checks

If blocking questions remain, do not move the file. Report what is missing and keep the plan in
`next/`. Non-blocking questions may remain only if the plan names the assumption and the impact if
the assumption is wrong.

## Dispatch

When the plan is ready:

1. Choose a destination under `_plans/open/`, preserving the existing filename when possible.
2. If the destination exists, append a unix-milliseconds stamp before `.md`.
3. Update the plan metadata from `status: next` to `status: open` when that field exists.
4. Move the plan from `_plans/next/` to `_plans/open/`.
5. Update `_plans/README.md`: remove it from `Next` and add it to `Open`.

Keep unrelated next/open entries unchanged. Do not alter done or discarded plans except to read
them for context.

## Completion

Report:

- Open plan path.
- Any assumptions that remain.
- Verification commands the implementation agent should run.
