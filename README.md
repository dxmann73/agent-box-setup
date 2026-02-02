# Dave Box Setup

Markdown-based setup documentation for configuring new coding agent VMs / machines.

## Why

1. To unlock the power of coding agents, they need to run in YOLO mode.
2. To reduce the blast radius, agents will need to run fully isolated in a sandbox.
3. To automate the setup itself, and also sync changes to the current setup to existing machines, we need a repo that holds both the configuration as well as the instructions to synchronize it.

## Usage

This repo is designed to work with coding agents. Just tell them to "Set up this machine using the dave-box-setup repo".

## What's Included

### Setup Guides (`setup/`)

| File | Description |
|------|-------------|
| `00-agent-setup.md` | Coding agent setup |
| `01-core-tools.md` | Git, terminal, package manager |
| `02-dev-environment.md` | Node.js, Python, development runtimes |
| `03-editor.md` | VS Code setup and extensions |
| `04-claude-setup.md` | Claude Code CLI installation |
| `05-voice-tools.md` | Wispr Flow voice input |
| `06-optional.md` | Docker, cloud CLIs, extras |

### Config Files (`configs/`)

Ready-to-use configuration files for common tools.

## Setting up for the first time

1. This repo has been cloned to /home/dave/projects/dave-box-setup
2. Follow the numbered guides in the `setup/` directory, see the section in "What's Included" below
3. Copy/symlink the configs from the `configs/` directory to the appropriate destinations
4. Verify with `SETUP.md` and generate a report.

## Synchronizing settings

TBD, we need a way to sync settings from / to machines
