# User Rules

This file is intended to give guidelines for the creation of rule

## Formatting

Make sure all rules are properly formatted with frontmatter tags like this:

```markdown
---
name: name of the rule
description: description of what the rule is supposed to accomplish
globs: Optional globs for files, gitignore-style, commma-separated
---
```

## File extension

Make sure file type is `mdc` so the links in @01-agent-setup.md work

## Project-specific rules

Each project should have an `AGENTS.md` file that reflects the content and context of the project. Each project should
have a `CLAUDE.md` symlink to this AGENTS.md file.
