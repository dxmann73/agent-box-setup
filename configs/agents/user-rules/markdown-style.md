---
name: markdown-style
description: Markdownlint rules to follow when generating markdown content
globs: [ '**.md', '**.mdc' ]
---

# Markdown Styling Rules

This project adheres to the [Markdownlint rules](https://github.com/DavidAnson/markdownlint). Follow these markdownlint rules when generating any markdown content.

## Critical Rules

### MD001 - Heading Levels Increment by One

Heading levels should only increment by one level at a time.

**Bad:**

```markdown
# Heading 1
### Heading 3
```

**Good:**

```markdown
# Heading 1
## Heading 2
### Heading 3
```

### MD003 - Consistent Heading Style

Use ATX-style headings (with `#`) consistently throughout documents.

**Good:**

```markdown
# Heading 1
## Heading 2
### Heading 3
```

**Avoid:**

```markdown
Heading 1
=========
```

### MD009 - No Trailing Spaces

Do not add trailing spaces at the end of lines, except for hard line breaks (2 spaces).

### MD013 - Line Length

Keep lines under 80 characters when possible. URLs and table rows are exempt.

**Exception:** Lines containing URLs, long code examples, or tables may exceed this limit.

### MD018 - Space After Hash

Always add a space after the hash characters in ATX-style headings.

**Bad:**

```markdown
#Heading 1
##Heading 2
```

**Good:**

```markdown
# Heading 1
## Heading 2
```

### MD022 - Headings Surrounded by Blank Lines

Headings should be surrounded by blank lines (one line above and below).

**Bad:**

```markdown
Some text
## Heading
More text
```

**Good:**

```markdown
Some text

## Heading

More text
```

### MD031 - Fenced Code Blocks Surrounded by Blank Lines

Fenced code blocks should be surrounded by blank lines.

**Bad:**

<!-- markdownlint-disable MD031 -->
```markdown
Some text
```bash
code here
```

<!-- markdownlint-enable MD031 -->

**Good:**

```markdown
Some text

```bash
code here
```

### MD032 - Lists Surrounded by Blank Lines

Lists should be surrounded by blank lines.

**Good:**

```markdown
Some text

- Item 1
- Item 2

More text
```

### MD047 - Files End with Newline

Files should end with a single newline character. This is handled automatically by most editors.

## List Formatting

### MD004 - Consistent List Style

Use consistent markers for unordered lists (prefer `-` or `*` throughout).

**Good:**

```markdown
- Item 1
- Item 2
  - Subitem 1
  - Subitem 2
```

### MD007 - List Indentation

Unordered list items should be indented by 2 spaces for sublists.

**Good:**

```markdown
- Item 1
  - Subitem 1
  - Subitem 2
- Item 2
```

### MD030 - Spaces After List Markers

Use one space after list markers.

**Bad:**

```markdown
-Item 1
*  Item 2
```

**Good:**

```markdown
- Item 1
* Item 2
```

## Code Blocks

### MD040 - Fenced Code Language

Always specify a language for fenced code blocks.

**Bad:**

<!-- markdownlint-disable MD040 -->
```
code here
```
<!-- markdownlint-enable MD040 -->

**Good:**

```bash
code here
```

Common languages: `bash`, `javascript`, `python`, `json`, `yaml`, `markdown`, `typescript`, `jsx`, `tsx`

## Emphasis and Strong

### MD049/MD050 - Consistent Emphasis Style

Use consistent style for emphasis (prefer `*` for italic and `**` for bold).

**Good:**

```markdown
*italic text*
**bold text**
```

## Links and Images

### MD042 - No Empty Links

Do not create empty links.

**Bad:**

```markdown
[link text]()
```

## Horizontal Rules

### MD035 - Consistent Horizontal Rule Style

Use consistent style for horizontal rules (prefer `---`).

**Good:**

```markdown
---
```

## Tables

### MD060 - Table Column Style

Table separator rows must have spaces after the opening pipe and before the
closing pipe.

**Bad:**

```markdown
| Name | Value |
|------|-------|
```

**Good:**

```markdown
| Name | Value |
| ---- | ----- |
```

## Application Guidelines

When generating markdown:

1. Always use ATX-style headings (`#`, `##`, `###`)
2. Add blank lines before and after headings, lists, and code blocks
3. Specify language for all code blocks
4. Keep lines under 80 characters when practical
5. Use consistent list markers (prefer `-`)
6. Always add space after `#` in headings
7. End files with a single newline
8. No trailing whitespace on lines

## When to Apply

Apply these rules when:

- Creating new markdown files
- Editing existing markdown files
- Generating documentation
- Writing README files
- Creating setup guides or instructions
- Formatting any markdown content for the user
