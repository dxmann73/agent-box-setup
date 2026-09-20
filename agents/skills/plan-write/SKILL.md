---
name: plan-write
description: Promote a selected draft into _plans/next/ for planning and
  refinement, then research and shape it there.
---

# Plan write

Promote one selected draft into `_plans/next/`, then refine it there with the user. The user is
choosing work, researching it with you, and resolving the decisions needed before dispatch.

This skill writes plans. It does not implement the plan.

## Inputs

The user may provide:

- A draft path from `_plans/drafts/`.
- A rank or title from a previous `plan-next` result.
- Extra research instructions, context, hunches, questions, or source names.

## Sources

Read `_plans/README.md` first; it is the source of truth for plan stages and repository rules.
Then read the selected draft completely and enough repository context to make a real plan:

- root `ROADMAP.md`, `VISION.md`, and `README.md` when present
- related plans in `_plans/next/`, `_plans/open/`, `_plans/done/`, and `_plans/discarded/`
- repository docs, code, tests, scripts, configuration, and recent git history relevant to the
  draft

Use outside sources only when the user asks for them or the draft names them. For Slack, email,
issue trackers, calendars, release channels, dashboards, logs, or other external systems, use an
available connected tool or plugin when present. If the source is not available, say exactly what
is missing and ask the user to connect it or paste/export the needed material. Do not invent
external evidence.

## Plan Format

Write the destination plan to `_plans/next/` with this structure, adapting headings only when the
work clearly needs it:

```markdown
# <plan title>

- source: `_plans/drafts/<draft>.md`
- priority: <copied or revised priority with reason>
- status: next
- written: <ISO 8601 date>

## Goal

## Non-goals

## Open Questions

## Background

## Evidence

## Decisions

## Implementation

## Acceptance Criteria

## Verification
```

Keep the draft's useful facts, but rewrite the plan for refinement. Do not preserve rambling draft
text unless it is valuable evidence. Preserve provenance by linking the source draft in metadata.

1. Write the promoted plan to `_plans/next/<name>.md`.
2. Remove the source draft after the destination exists.
3. Update `_plans/README.md` so the plan appears under `Next`.

Keep unrelated next/open entries unchanged. Do not alter done or discarded plans except to read
them for context.

## Research And Design

After the draft is in `_plans/next/`, work with the user until the plan is ready to dispatch.
Gather evidence, test assumptions, and narrow the scope. The shape depends on the work:

- For a bug or incident, identify the symptom, prove or disprove likely causes, name the most
  likely cause, name the change to make, and specify the verification that would prove it worked.
- For a feature, write the product and technical spec: user outcome, constraints, data/control
  flow, UI/API behavior when relevant, acceptance criteria, risks, and tests.
- For cleanup or infrastructure work, define the target state, migration path, rollback or safety
  checks, and commands that prove the repo or system is still healthy.
- For research or exploratory work, define questions, hypothesis, and verification.

Ask design questions when they matter. If a question cannot be answered yet, keep it in the plan
under `Open Questions` with the best current assumption and the impact if that assumption is wrong.

The plan should contain sections for:

- Clear goal and non-goals.
- Relevant evidence and links or file references.
- Decisions made during planning.
- Step-by-step implementation outline.
- Acceptance criteria.
- Verification commands or checks.
- Open questions, if any, with assumptions and impact.

Mark unresolved items plainly. This skill keeps the plan in `next/`; `plan-dispatch` moves it to
`open/` when blocking questions are resolved and implementation is starting.

## Completion

Report:

- Destination path.
- Source draft removed.
- Key decisions or research added in this pass.
- Remaining open questions, if any.
- Dispatch readiness: whether blocking questions remain before `plan-dispatch`.
