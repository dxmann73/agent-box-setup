# Claude Instructions for Dave Box Setup

This repository contains instructions for setting up a new Ubuntu development machine.

## How to Use This Repo

1. **Follow the numbered setup files in order** - Each file in `setup/` is numbered for sequential execution
2. **Verify each step** - Run the verification command after each installation before proceeding
3. **Copy configs** - Use files from `configs/` directory as templates

## Setup Order

1. `setup/01-home-environment.md` - Shell configuration and dotfiles
2. `setup/02-core-tools.md` - Package manager, Git, terminal basics
3. `setup/03-dev-environment.md` - Node.js and development tools
4. `setup/04-editor.md` - VS Code and extensions
5. `setup/06-voice-tools.md` - Voice input tools
6. `setup/07-optional.md` - Docker, cloud CLIs, extras

## Important Notes

- **Don't run everything blindly** - Ask the user before installing optional tools
- **Check existing installations** - Many tools may already be installed; verify first
- **Respect user preferences** - These are Dave's defaults; the user may want variations
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
