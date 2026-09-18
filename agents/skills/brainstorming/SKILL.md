---
name: brainstorming
description: >
  Explore requirements, options, and approach before implementation. Use when creating or changing
  a plan or design. Does not write plan files.
---

# Brainstorming

Turn ideas into agreed design before implementation. Engineering style, repo conventions, and
existing specs live in **AGENTS.md**, **README.md**, and (per project) **SDDs, PRDs, ADRs, use
cases** — read those first, not restate here.

This skill does not write plans. Plans live in `_plans/` when they exist; other skills own that
tree. Do not create, move, or edit files under `_plans/`, `plans/`, `incoming/`, or `_incoming/`.

Plans and designs describe required changes only. Do not pad with behavior that already exists,
things that stay unchanged, or work that does not need doing.

## Hard gate

No implement, scaffold, or invoke implementation skills until the design is presented and approved
in conversation. Applies even to "small" work; design may be few sentences.

## Flow (in order)

1. **Context** — Repo state, docs above, code layout; if the ask is multiple independent systems,
   decompose before detail work.
2. **Visual companion** — If visuals help soon, offer in **own message** (see `visual-companion.md`).
   Else skip.
3. **Questions** — One per message; prefer multiple choice; nail purpose, constraints, success
   criteria.
4. **Options** — Two or three approaches with trade-offs and recommendation; cut scope with YAGNI
   unless the user insists.
5. **Design** — Present in conversation, scaled to complexity (architecture, data flow, errors,
   testing at a level appropriate to the work). Do not write a plan or spec file.
6. **Approval** — Ask the user to approve or request edits. Stay in chat until they do.
7. **Stop** — After approval, wait. Do not invoke writing-plans or any other skill that creates
   plan files.

## Visual companion

Offer once when mockups, diagrams, or layout comparisons likely. Details:
`skills/brainstorming/visual-companion.md`.
