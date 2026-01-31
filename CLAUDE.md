# Claude Instructions for Dave Box Setup

This repository contains instructions for setting up a new development machine. You (Claude) can use these docs to configure Windows, Linux, or VM environments.

## How to Use This Repo

1. **Determine the target platform** - Ask the user what OS they're setting up (Windows, Linux distro, or VM)
2. **Follow the numbered setup files in order** - Each file in `setup/` is numbered for sequential execution
3. **Adapt commands to the platform** - Instructions include platform-specific variants where needed
4. **Verify each step** - Run the verification command after each installation before proceeding
5. **Copy configs** - Use files from `configs/` directory as templates

## Setup Order

1. `setup/01-core-tools.md` - Package manager, Git, terminal basics
2. `setup/02-dev-environment.md` - Node.js, Python, development runtimes
3. `setup/03-editor.md` - VS Code and extensions
4. `setup/04-claude-setup.md` - Claude Code CLI and configuration
5. `setup/05-voice-tools.md` - Wispr Flow and voice input
6. `setup/06-optional.md` - Docker, cloud CLIs, extras

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
