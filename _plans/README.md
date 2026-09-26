# Plans

This file is the source of truth for plan stages, transitions, and repository-specific planning
rules.

Drafts, done, and discarded stay in their folders and are not listed here.

## Stages

A plan lives in exactly one directory. That directory is its stage.

| Stage     | Directory    | Means                                                         |
| --------- | ------------ | ------------------------------------------------------------- |
| Draft     | `drafts/`    | Captured idea, not selected yet.                              |
| Next      | `next/`      | Selected for planning and refinement. Listed above.           |
| Open      | `open/`      | Actively being implemented. Listed above.                     |
| Done      | `done/`      | Finished and verified.                                        |
| Discarded | `discarded/` | Abandoned. Kept, because why it was dropped is worth knowing. |

Changing a plan's stage means moving its file. A plan is never in two directories at once, and is
never copied into a second one.

The usual path is `drafts/` -> `next/` -> `open/` -> `done`. Any stage can go to
`discarded/`. Plans move backwards too: `open/` -> `next/` when work stalls,
`next/` -> `drafts/` when the decision to plan it is withdrawn.

## Transitions

- `drafts/` -> `next/`: the user selected the draft for planning and refinement.
- `next/` -> `open/`: blocking questions are resolved, scope is clear, verification is written,
  and implementation is starting.
- `open/` -> `done/`: implementation is complete and verification passed.
- Any stage -> `discarded/`: the plan is no longer wanted; record the reason in the plan.

## Plan readiness

A plan in `next/` may still contain open questions, assumptions, and research notes.

A plan in `open/` should have:

- clear goal and non-goals
- resolved blocking design questions
- implementation outline
- acceptance criteria
- verification commands or checks

Update the Next and Open sections above whenever a plan enters or leaves `next/` or `open/`. Those
two sections are the index. The other three stages are not listed.

## Next

## Open

- [Move BB projects from the host OS onto the agent VM](open/move-bb-projects-to-agent-vm.md) — p1

## Repository rules

Rules that apply to this repository only, on top of the stage moves above - anything that must
happen when a plan is added, selected for refinement, dispatched, finished, or discarded here.

(none yet)
