---
name: new-project
description: Conventions for bootstrapping a new project or GitHub repo — instruction files, visibility, stack-relevant skill references. Use when creating a new project or repo, or wiring agent instructions into a fresh codebase.
---

# New project setup

## Overview

Applies when a project or repo is created from scratch, or when an existing codebase gets agent
instructions for the first time.

## Workflow

1. Instruction files:
   - Create a repo-root `AGENTS.md` with project-specific guidance (stack, commands, conventions).
   - Add `CLAUDE.md` as a symlink to `AGENTS.md`: `ln -s AGENTS.md CLAUDE.md`.
   - Keep global preferences out of it; those live in `~/AGENTS.md`.

2. Repo visibility:
   - Create GitHub repos private by default.
   - Only make a repo public when the user asks.

3. Stack and skills:
   - Determine the actual stack before writing guidance (read the code, not the README alone).
   - Reference only the skills relevant to that stack; skip unrelated ones.

4. Bootstrapping edits:
   - Reuse existing project conventions (formatting, naming, directory layout).
   - Avoid broad rewrites of existing code while bootstrapping.

5. Report what was created: files, symlinks, repo visibility.

## Boundaries

- Do not push or publish a repo unless the user asks.
- Do not copy the full global rule file into the project.
