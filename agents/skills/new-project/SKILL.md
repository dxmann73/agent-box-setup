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

2. Scaffolding files:
   - Copy the canonical markdownlint config into the repo root:
     `cp ~/projects/agent-box-setup/.markdownlint.json .markdownlint.json`
   - It is the source of truth for `MD013` line length (100) and the repo-wide rule set; the
     `markdownlint` skill reads it. Do not hand-write a variant.
   - Add a `.markdownlintignore` exempting plan artifacts, plus any generated or vendored
     directories the stack produces (`node_modules`, `dist`, `build`, `coverage`, `target`):

     ```text
     plans/
     *-plan.md
     ```

   - Add a `.gitignore` matching the stack before the first commit.

3. Repo visibility:
   - Create GitHub repos private by default.
   - Only make a repo public when the user asks.

4. Stack and skills:
   - Determine the actual stack before writing guidance (read the code, not the README alone).
   - Reference only the skills relevant to that stack; skip unrelated ones.

5. Bootstrapping edits:
   - Reuse existing project conventions (formatting, naming, directory layout).
   - Avoid broad rewrites of existing code while bootstrapping.

6. Project workspace:
   - For a repository created under `~/projects`, update `~/projects/projects.code-workspace` so
     VS Code includes it.
   - Keep the project table in `~/projects/agent-box-setup/projects/README.md` in sync with the
     project directories and VS Code workspace.
   - Preserve existing workspace folders and settings; add the new project once.

7. Report what was created: files, symlinks, scaffolding, repo visibility, and workspace
   updates.

## Boundaries

- Do not push or publish a repo unless the user asks.
- Do not copy the full global rule file into the project.
