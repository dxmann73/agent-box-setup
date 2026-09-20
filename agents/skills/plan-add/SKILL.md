---
name: plan-add
description: Capture a thought as a draft plan under _plans/drafts/ so it is not
  forgotten. Use for /plan-add, or when the user wants an idea, a request, or an
  alert written down without working on it now.
---

# Plan add

Capture a thought and save it as a draft. Make no decisions about the work itself. The user wants
it out of their head, not solved.

This skill writes into `drafts/` only.

## Scope

- Target is the current workspace.
- Read `_plans/README.md` when present; it is the source of truth for plan stages and repository
  rules.
- Otherwise read only `_plans/`, the current repository name and branch, plus the cheap git signals
  named under "Surroundings".

## Steps

1. Resolve the workspace root.
2. Infer a title, a kebab-case slug, and a priority with its evidence, from the captured text.
3. If `_plans/` does not exist, follow "Uninitialized repository" below and stop.
4. Scan `_plans/` for an overlapping plan.
5. If a plan overlaps, follow "Overlap" below and stop.
6. Otherwise write `_plans/drafts/<slug>.md` in the format below.
7. Check the surroundings per "Surroundings" below. Record what you find in the draft's
   `Observations` section, if anything.
8. Report the path written, the inferred priority with its basis, any `Related` link added, and any
   observation surfaced.

## Naming

If `_plans/drafts/<slug>.md` already exists, do keep the existing file untouched and append a
unix-milliseconds stamp to the new one.

## File format

```markdown
# <inferred title>

- created: <ISO 8601 date>
- priority: <p0 (urgent) | p1 (high) | p2 (medium) | p3 (low) | p4 (later)> — <evidence, a few words>
- source: <where this came from, when known>
- branch: <current branch>

<the captured text, verbatim>

## Related

- `_plans/next/some-other-plan.md` — <one line on how it overlaps>

## Observations

- <a cheap signal the plan creator may not know, one line each>

---

Also see `_plans/README.md` and the project `README.md` for any rules that apply.
```

- Preserve the captured text verbatim. It is evidence of what was actually said. Add a title and
  metadata around it. Do not paraphrase it, summarize it, or correct it.
- Write `source` only when the origin is actually known, such as a Slack message the user pasted
  in. If it is unknown, omit the field.
- Write the `Related` section only when the scan found a real match.
- Write the `Observations` section only when the surroundings check found something real; see
  "Surroundings" below.

## Priority

| Level | Name   | Means                                                |
| ----- | ------ | ---------------------------------------------------- |
| `p0`  | urgent | Happening now, users affected, drop other work.      |
| `p1`  | high   | Real damage or a hard deadline, but not this minute. |
| `p2`  | medium | Should happen, nothing breaks if it slips a week.    |
| `p3`  | low    | Wanted, no urgency attached.                         |
| `p4`  | later  | Explicitly deferred. Someday, nice to have.          |

Write the code and the word together. `p1` alone is opaque to a person skimming the file.

Signals that raise the level: a live alert, users or clients already affected, an error rate, an
outage, a deadline, an explicit ask from a named person. Signals that lower it: an idea, a
refactor, no stated consequence. Words such as "someday", "at some point", or "nice to have" are an
explicit deferral and mean `p4`.

Always write the evidence next to the value. A bare `priority: p0` cannot be reviewed.
`priority: p0 (urgent) — alert firing, clients already receiving 500` can be argued
with.

When the text carries no urgency signal at all, write
`priority: p3 (low) — no urgency signal in the text`. State the absence. Do not quietly pick a
middle value, and do not use `p4`: `p4` means the user deferred the work, and you do not defer work
on the user's behalf.

Report the inferred priority and its basis in the final output, and say the value can be edited in
the file. Do not stop and ask.

## Scan

Before finishing, scan `_plans/` for a plan covering the same ground: filenames and titles across.
If nothing matches, write the draft and finish.

## Overlap

If a plan overlaps, stop and report the match. Do not decide alone. An overlap means the requesting
party forgot something or scoped it wrong, so the requesting party resolves it. Offer three
choices:

1. Move the existing material into the new draft. The new draft becomes the home of the topic, and
   the overlapping part leaves the older plan.
2. Add the new material to the existing plan. No new file.
3. Split the whole thing. The overlap is real, the two concerns are separate, so redraw the
   boundary explicitly.

This is the only point where this skill interrupts. Everywhere else it completes silently.

## Surroundings

The creator captures from memory. The workspace may already contradict or pre-empt the thought.
Look, record what matters. Observe only — never act, never touch the verbatim captured text.

Cheap signals only (this is capture, not research):

- Repository name and current branch.
- `git status --porcelain` — dirty or untracked files.
- `git log --oneline -20` — recent commit subjects.
- `_plans/` filenames and titles (already read for the scan).
- The root `docs/` tree, if present

Record a signal under `Observations` only when real and relevant — one plain line, signal plus why
it matters.

## Uninitialized repository

Never run `plan-init`. Other agents may be working in the repository right now, and `plan-init`
moves `plans/`, `_incoming/`, and `incoming/` contents into `_plans/drafts/` and removes those
directories.

Never create a partial `_plans/` either. `plan-init` refuses any `_plans/` that is not its exact
layout:

```text
_plans/ exists but is not the plan-init layout; refusing to change it
```

A bare `_plans/drafts/` would permanently block the command this warning tells the user to run.

Instead, write the draft to `_incoming/<slug>.md` at the repository root, in the same format as any
other draft, and warn:

```text
No _plans/ in this repository. Saved to _incoming/<slug>.md.
Run plan-init to set up _plans/; it will move this into _plans/drafts/.
```

`plan-init` imports `_incoming/` on first init, so the next run moves the file into
`_plans/drafts/` and removes `_incoming/`. Nothing is restructured and the thought is not lost.

Skip the scan in this case, since there is no `_plans/` to scan.

## Completion

Done when one file exists — `_plans/drafts/<slug>.md`, or `_incoming/<slug>.md` in an uninitialized
repository — holding the captured text verbatim with its metadata and the footer, and the user has
been told the path and the inferred priority. `_plans/README.md` is unchanged: drafts are not
listed in the index.
