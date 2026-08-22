---
name: gg-commit-push
description: Git commit-and-push workflow for the shorthand command GG. Use when the user says "GG" or "gg" and expects immediate commit and push of current workspace changes.
---

# GG Commit Push

## Overview

Interpret `GG` as an explicit instruction to commit and push.

Follow a deterministic workflow so the action is fast, safe, and auditable.

## Workflow

1. Inspect repo state:
   - Run `git status --short --branch`.
   - If there are no changes, report `nothing to commit` and stop.
   - Assume parallel agents may be working; do not assume all visible changes belong to this run.

2. Build and verify agent workset:
   - Track files edited/created by this agent during the current run (`agent_workset`).
   - If `agent_workset` is empty, report and stop.
   - If ownership of changed files is ambiguous, stop and ask before staging.

3. Stage only the workset:
   - Run `git add -- <agent_workset paths...>`.
   - Never run `git add -A` for `GG`.
   - Verify staged files exactly match `agent_workset`:
     - `git diff --staged --name-only`
   - If any extra file is staged, unstage and stop to resolve mismatch.

4. Create commit:
   - Summarize changes from `git diff --staged --name-status` and `git diff --staged`.
   - Write a Conventional Commit message: `type: summary`.
   - Prefer `feat`, `fix`, `refactor`, `docs`, `test`, `chore`, `build`, `ci`, `perf`, or `style`.
   - Run `git commit -m "<message>"`.

5. Push:
   - Detect current branch with `git branch --show-current`.
   - If upstream exists, run `git push`.
   - If upstream does not exist, run `git push -u origin <branch>`.

6. Report outcome:
   - Return commit hash, commit message, branch, and push result.

## Failure Handling

- If commit fails because there are no staged changes, report and stop.
- If staged files differ from `agent_workset`, unstage extras and stop.
- If push fails (auth, non-fast-forward, protected branch, network), do not force-push.
- Report exact error and ask for next instruction.

## Boundaries

- Do not use destructive git operations.
- Do not rewrite history (`--amend`, rebase, force-push) unless explicitly requested.
