# Instructions for setting up an Agent Box

This repository contains instructions for setting up a new Ubuntu development machine to use to run agents in YOLO mode.

## How to Use This Repo

1. **Follow the numbered setup files in order** - Each file in `setup/` is numbered for sequential execution
2. **Verify each step** - Run the verification command after each installation before proceeding
3. **Copy configs** - Use files from `configs/` directory as templates

## Setup Order

1. [setup/00-home-environment.md](setup/00-home-environment.md) - Shell configuration and dotfiles
2. [setup/01-agent-setup.md](setup/01-agent-setup.md) - Claude Code, Cursor CLI, agent rules
3. [setup/02-core-tools.md](setup/02-core-tools.md) - GitHub CLI, jq, Docker
4. [setup/03-dev-environment.md](setup/03-dev-environment.md) - Node.js and development tools
5. [setup/04-ide+tooling.md](setup/04-ide+tooling.md) - Cursor IDE
6. [setup/05-voice-tools-a-faster-whisper.md](setup/05-voice-tools-a-faster-whisper.md) - Voice input (faster-whisper)
7. [setup/05-voice-tools-b-nerd-dictation.md](setup/05-voice-tools-b-nerd-dictation.md) - Voice input (nerd-dictation alternative)
8. [setup/06-optional.md](setup/06-optional.md) - Helm, cloud CLIs, extras

## Important Notes

- **Don't run everything blindly** - Ask the user before installing optional tools
- **Check existing installations** - Many tools may already be installed; verify first
- **Respect user preferences** - These are defaults; the user may want variations
- **Handle errors gracefully** - If a step fails, diagnose before continuing

## Config Files

The `configs/` directory contains actual configuration files:

- `.gitconfig` - Git configuration (update email/name as needed)
- `.bashrc` - Shell customizations
- `vscode/settings.json` - VS Code settings

Copy these to the appropriate locations, or symlink them for easier updates.

## Structure

- `setup/` - Numbered setup guides (follow in order)
- `configs/` - Configuration files to copy/symlink
- `setup-checklist.md` - Master verification checklist
