---
name: markdownlint
description: Use when creating or editing Markdown files (.md/.mdc), fixing markdownlint issues,
  or reviewing Markdown formatting. This skill contains the Markdown style rules and lint workflow.
  Always use `.markdownlint.json` as the line-length source of truth and honor
  `.markdownlintignore`.
---

# Markdownlint

## Overview

Use for all Markdown authoring and markdownlint workflows. Single source of truth for Markdown formatting.

## Source of Truth

1. Lint config: `.markdownlint.json`
2. Ignore: `.markdownlintignore`

For `MD013` line length, read `.markdownlint.json` and follow that value. No config → `prettier-wrap.sh` defaults to `100`.

## Core Rules

- MD001: heading levels increment by one.
- MD003: ATX headings (`#`, `##`, `###`) consistently.
- MD009: no trailing spaces (except explicit hard breaks).
- MD013: line length follows `.markdownlint.json`.
- MD018: space after `#` in ATX headings.
- MD022: surround headings with blank lines.
- MD031: surround fenced code blocks with blank lines.
- MD032: surround lists with blank lines.
- MD047: end files with single newline.
- MD004/MD007/MD030: consistent list marker style, indentation, spacing.
- MD040: specify language for fenced code blocks.
- MD042: no empty links (`[text]()`).
- MD035: consistent horizontal rule style (`---`).
- MD060: spaced table separators (`| ---- |`).

## Workflow

> **Note:** Never apply to plan artifacts (`plans/**/*.md`, `**/*-plan.md`). Plans exempt from linting and wrapping.

1. Edit Markdown per core rules.
1. Wrap/reflow prose with Prettier (line width from `.markdownlint.json`):

```bash
bash ~/projects/agent-box-setup/configs/agents/skills/markdownlint/scripts/prettier-wrap.sh
```

1. Lint with ignore-path support:

```bash
bash ~/projects/agent-box-setup/configs/agents/skills/markdownlint/scripts/lint-fix.sh
```

Lint script prefers `markdownlint` or `markdownlint-cli` if installed; falls back to `npx --yes markdownlint-cli` on demand.

1. Check-only lint (no `--fix`):

```bash
npx --yes markdownlint-cli --config .markdownlint.json --ignore-path .markdownlintignore \
  "**/*.md" "**/*.mdc"
```

Both scripts accept optional file/directory/glob targets. Default: `"**/*.md"` and `"**/*.mdc"`, honoring `.markdownlintignore`.

Persistent install:

```bash
npm install -g markdownlint-cli
```

## Guardrails

- Never hardcode line length; always defer to `.markdownlint.json`.
- Always respect `.markdownlintignore` during lint runs.
- Never lint plan artifacts: skip `plans/**/*.md` and `**/*-plan.md`.
- Don't change `.markdownlint.json` or `.markdownlintignore` unless user asks.