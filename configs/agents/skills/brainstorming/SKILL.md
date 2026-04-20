---
name: brainstorming
description: "You MUST use this before any creative work - creating features, building components, adding functionality, or modifying behavior. Explores user intent, requirements and design before implementation."
---

# Brainstorming

Turn ideas into agreed design before implementation. Engineering style, plans, repo conventions live in **AGENTS.md**, **README.md**, and (per project) **SDDs, PRDs, ADRs, specs, use cases** — read those first, not restate here.

Example (nomap): planning/design artifacts live under repo-root `plans/`; checked-in system description lives under `docs/sdd/`. Follow target project layout when different.

## Hard gate

No implement, scaffold, or invoke implementation skills until design presented and approved. Applies even to "small" work; design may be few sentences.

## Flow (in order)

1. **Context** — Repo state, docs above, code layout; if ask is multiple independent systems, decompose before detail work.
2. **Visual companion** — If visuals help soon, offer in **own message** (see `visual-companion.md`). Else skip.
3. **Questions** — One per message; prefer multiple choice; nail purpose, constraints, success criteria.
4. **Options** — Two or three approaches with trade-offs and recommendation; cut scope with YAGNI unless user insists.
5. **Design** — Sections scaled to complexity; confirm as you go (architecture, data flow, errors, testing at level appropriate to work).
6. **Written artifact** — Default location: `plans/YYYY-MM-DD-<topic>-design.md` at repo root (same folder as implementation plans in `~/AGENTS.md`, which use `YYYY-MM-DD-<topic>-plan.md`). Obey project rules if specify another path or naming.
7. **Self-review the file** — Fix placeholders/TODOs, internal contradictions, ambiguous requirements, scope that should split into multiple specs.
8. **User review** — Ask user to read committed file and approve or request edits before planning.
9. **Next** — Invoke **writing-plans** only. No jump to frontend-design, MCP builders, or other implementation skills.

## Visual companion

Offer once when mockups, diagrams, or layout comparisons likely. Details:
`skills/brainstorming/visual-companion.md`.