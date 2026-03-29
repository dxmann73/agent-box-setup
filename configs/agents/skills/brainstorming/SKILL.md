---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming

Turn ideas into an agreed design before implementation. Engineering style, plans, and repo
conventions live in **AGENTS.md**, **README.md**, and (per project) **SDDs, PRDs, ADRs, specs,
and use cases** — read those first so you do not restate them here.

Example (nomap): planning and design artifacts live under repo-root `plans/`; the checked-in system
description lives under `docs/sdd/`. Follow the target project’s layout when it differs.

## Hard gate

Do not implement, scaffold, or invoke implementation skills until a design is presented and
approved. Applies even to “small” work; the design may be a few sentences.

## Flow (in order)

1. **Context** — Repo state, docs above, code layout; if the ask is multiple independent systems,
   decompose before detail work.
2. **Visual companion** — If visuals will help soon, offer it in **its own message** (see
   `visual-companion.md`). Otherwise skip.
3. **Questions** — One per message; prefer multiple choice; nail purpose, constraints, success
   criteria.
4. **Options** — Two or three approaches with trade-offs and a recommendation; cut scope with
   YAGNI unless the user insists.
5. **Design** — Sections scaled to complexity; confirm as you go (architecture, data flow, errors,
   testing at a level appropriate to the work).
6. **Written artifact** — Default location: `plans/YYYY-MM-DD-<topic>-design.md` at repo root (same
   folder as implementation plans in `~/AGENTS.md`, which use `YYYY-MM-DD-<topic>-plan.md`). Obey
   project rules if they specify another path or naming.
7. **Self-review the file** — Fix placeholders/TODOs, internal contradictions, ambiguous
   requirements, and scope that should split into multiple specs.
8. **User review** — Ask the user to read the committed file and approve or request edits before
   planning.
9. **Next** — Invoke **writing-plans** only. Do not jump to frontend-design, MCP builders, or other
   implementation skills.

## Visual companion

Offer once when mockups, diagrams, or layout comparisons are likely. Details:
`skills/brainstorming/visual-companion.md`.
