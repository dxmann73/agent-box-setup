# 04 - Claude Code Setup

Install and configure Claude Code CLI.

## Prerequisites

- Completed `01-core-tools.md` (Node.js required)
- Anthropic API key or Claude Pro subscription

---

## 1. Install Claude Code CLI

```bash
npm install -g @anthropic-ai/claude-code
```

**Verify:**
```bash
claude --version
```

---

## 2. Authentication

Run Claude and follow the authentication prompts:

```bash
claude
```

You'll be prompted to either:
- Log in with your Claude account (Pro/Team subscription)
- Enter an Anthropic API key

---

## 3. Configuration

Claude Code stores config in `~/.claude/`

### Set Default Model (Optional)

```bash
claude config set model claude-sonnet-4-20250514
```

### Enable/Disable Features

```bash
# View current settings
claude config list
```

---

## 4. Project Setup

When starting a new project, create a `CLAUDE.md` file in the root:

```bash
# In your project directory
claude init
```

This creates a `CLAUDE.md` with project-specific instructions for Claude.

---

## 5. VS Code Integration

If you installed the Claude extension in `03-editor.md`, it should automatically detect the CLI.

Verify by:
1. Open VS Code
2. Open Command Palette (`Ctrl+Shift+P`)
3. Type "Claude" to see available commands

---

## 6. Terminal Integration

Claude works best with a good terminal setup:

### Windows Terminal
- Ensure you can run `claude` from Git Bash or PowerShell
- Consider adding to Windows Terminal profiles

### Shell Aliases (Optional)

Add to your `.bashrc` or `.zshrc`:
```bash
alias c='claude'
alias cc='claude --continue'
```

---

## Verification Checklist

- [ ] Claude CLI installed (`claude --version`)
- [ ] Authentication complete (`claude` runs without errors)
- [ ] VS Code extension working (if installed)

**Next:** Continue to `05-voice-tools.md`
