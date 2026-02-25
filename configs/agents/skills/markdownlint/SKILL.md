---
name: markdownlint
description: Use when creating or editing Markdown files (.md/.mdc), fixing markdownlint issues,
  or reviewing Markdown formatting. This skill contains the Markdown style rules and lint workflow.
  Always use `.markdownlint.json` as the line-length source of truth and honor
  `.markdownlintignore`.
---

# Markdownlint

## Overview

Use this skill for all Markdown authoring and markdownlint workflows in this repository.
This is the single source of truth for Markdown formatting behavior.

## Source of Truth

1. Lint configuration: `.markdownlint.json`
2. Ignore behavior: `.markdownlintignore`

For `MD013` line length, always read `.markdownlint.json` and follow that value.
Lines should wrap according to the value configured in .markdownlint.json

## Core Rules

Apply these rules when writing or editing Markdown:

- MD001: heading levels increment by one.
- MD003: use ATX headings (`#`, `##`, `###`) consistently.
- MD009: no trailing spaces (except explicit hard breaks).
- MD013: line length follows `.markdownlint.json`.
- MD018: add a space after `#` in ATX headings.
- MD022: surround headings with blank lines.
- MD031: surround fenced code blocks with blank lines.
- MD032: surround lists with blank lines.
- MD047: end files with a single newline.
- MD004/MD007/MD030: keep list marker style, indentation, and spacing consistent.
- MD040: specify a language for fenced code blocks.
- MD042: no empty links (`[text]()`).
- MD035: consistent horizontal rule style (`---`).
- MD060: use spaced table separators (`| ---- |`).

## Workflow

1. Read active line length before broad edits:

```bash
jq -r '.MD013.line_length // "unset"' .markdownlint.json
```

1. Make Markdown edits following the core rules above.
1. Lint with ignore-path support:

```bash
npx --yes markdownlint-cli --ignore-path .markdownlintignore "**/*.md" "**/*.mdc"
```

1. If requested, run auto-fix and then lint again:

```bash
npx --yes markdownlint-cli --ignore-path .markdownlintignore --fix "**/*.md" "**/*.mdc"
npx --yes markdownlint-cli --ignore-path .markdownlintignore "**/*.md" "**/*.mdc"
```

## Guardrails

- Do not hardcode line length in instructions or decisions; always defer to `.markdownlint.json`.
- Always respect `.markdownlintignore` during lint runs.
- Do not change `.markdownlint.json` or `.markdownlintignore` unless the user asks.
