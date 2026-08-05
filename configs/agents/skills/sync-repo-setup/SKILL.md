---
name: sync-repo-setup
description: Synchronize repo-level agent and tooling setup against agent-box-setup and report drift. Use when the user says "do a sync run", asks to sync repo setup, or wants AGENTS/README references realigned.
---

# Repo sync setup

## Overview

A sync run checks the current project against `~/projects/agent-box-setup` and reports what drifted.
It touches repo-level files only.

## Workflow

1. Check for drift against `agent-box-setup`:
   - Compare repo-level conventions (instruction files, lint config, scripts) with the box setup.
   - Note anything referenced but missing, or present but no longer documented.

2. Verify linked skills and instruction files:
   - Repo-root `AGENTS.md` exists, `CLAUDE.md` is a symlink to it.
   - Skills referenced by `AGENTS.md` exist in `configs/agents/skills/` on the box.
   - Determine the current tool stack and keep the referenced skills aligned with it.

3. Align `AGENTS.md` and `README.md` references:
   - Fix stale paths, renamed files, and dead links.
   - Keep both files consistent with each other.

4. Report what changed:
   - List edits made, drift found but not fixed, and anything that needs a decision.

## Boundaries

- Synchronize repo-level files only (`AGENTS.md`, `CLAUDE.md`, project docs, local conventions).
- Preserve existing project structure and preferences; no destructive overwrites.
- If sync inputs conflict, ask for direction before changing policy-level files.
