# Dave Box Setup

Markdown-based setup documentation for configuring new development machines. Designed to be followed by both humans and AI agents (like Claude).

## Quick Start

1. Clone this repo to your new machine
2. Follow the numbered guides in `setup/` directory
3. Copy/symlink configs from `configs/` directory
4. Verify with `setup-checklist.md`

## What's Included

### Setup Guides (`setup/`)

| File | Description |
|------|-------------|
| `01-core-tools.md` | Git, terminal, package manager |
| `02-dev-environment.md` | Node.js, Python, development runtimes |
| `03-editor.md` | VS Code setup and extensions |
| `04-claude-setup.md` | Claude Code CLI installation |
| `05-voice-tools.md` | Wispr Flow voice input |
| `06-optional.md` | Docker, cloud CLIs, extras |

### Config Files (`configs/`)

Ready-to-use configuration files for common tools.

## Using with Claude

This repo is designed to work with Claude Code. Just tell Claude:

> "Set up this machine using the dave-box-setup repo"

Claude will read `CLAUDE.md` for instructions and follow the setup guides.

## Platform Support

Instructions include variants for:
- **Windows** - Using winget, scoop, or manual installers
- **Linux** - apt, dnf, or other package managers
- **macOS** - Homebrew

## Customizing

Fork this repo and modify for your own preferences. The markdown format makes it easy to add, remove, or reorder steps.
