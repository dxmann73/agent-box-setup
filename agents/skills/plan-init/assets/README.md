# Plans

This file contains the plan stages, and how plans move between stages in this repository.

Drafts, done, and discarded stay in their folders and are not listed here.

## Stages

A plan lives in exactly one directory. That directory is its stage.

| Stage     | Directory    | Means                                                         |
| --------- | ------------ | ------------------------------------------------------------- |
| Draft     | `drafts/`    | Captured, not ready to queue. No decisions yet.               |
| Next      | `next/`      | Queued. Decided, not started. Listed above.                   |
| Open      | `open/`      | In flight. Someone is working on it now. Listed above.        |
| Done      | `done/`      | Finished.                                                     |
| Discarded | `discarded/` | Abandoned. Kept, because why it was dropped is worth knowing. |

Changing a plan's stage means moving its file. A plan is never in two directories at once, and is
never copied into a second one.

The usual path is `drafts/` → `next/` → `open/` → `done/`. Any stage can go to `discarded/`. Plans
move backwards too: `open/` → `next/` when work stalls, `next/` → `drafts/` when the decision to do
it is withdrawn.

Update the Next and Open sections above whenever a plan enters or leaves `next/` or `open/`. Those
two sections are the index. The other three stages are not listed.

## Next

(none)

## Open

(none)

## Repository rules

Rules that apply to this repository only, on top of the stage moves above — anything that must
happen when a plan is added, queued, started, finished, or discarded here.

(none yet)
