---
name: verification-before-completion
description: Use befory you claim work is done/complete, refactoring, bug fixed, or passing, before committing or creating PRs - running verification commands as specified in the repo and confirming output before making any success claims; evidence before assertions always
---

# Verification Before Completion

## Overview

Never say work is complete without verification.
You have to run the appropriate verification commands.
NO COMPLETION CLAIMS WITHOUT FRESH VERIFICATION EVIDENCE

## The Gate Function

BEFORE claiming any status or expressing satisfaction:

1. IDENTIFY: What command proves this claim? Usually there are scripts in the repo / README / AGENTS.md
2. RUN: Execute the FULL commands (fresh, complete)
3. READ: Full output, check exit code, count failures
4. VERIFY: Does output confirm the claim?
   - If NO: State actual status with evidence
   - If YES: State claim WITH evidence
5. ONLY THEN: Make the claim

For app/code changes, do not stop at the smallest command that happens to pass.
Use the strongest practical verification command available locally.

Minimum default:

- Run a full build for every app/package you changed when a build exists
- If there is a quick way to start the app or service, start it and confirm it comes up
- Always run a typecheck if available, not only tests
- For bigger changes, make sure the app starts

## Apply **ALWAYS before:**

- ANY variation of success/completion claims
- ANY expression of satisfaction
- ANY positive statement about work state
- Committing, PR creation, task completion
