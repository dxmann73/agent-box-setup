# Agent Box Setup

Markdown-based setup documentation for configuring new coding agent VMs / machines.

The steps outlined here will assume you have already done the [bootstrapping](./BOOTSTRAP.md)!

## Why

1. To unlock the power of coding agents, they need to run in YOLO mode.
2. To reduce the blast radius, agents will need to run fully isolated in a sandbox.
3. To automate the setup itself, and also sync changes to the current setup to existing machines, we need a repo that holds both the configuration as well as the instructions to synchronize it.

## Usage

This repo is designed to work with coding agents. Just tell them to "Set up this machine using the agent-box-setup repo".

## What's Included

### Setup Guides (`setup/`)

| File | Description |
| ---- | ----------- |
| `00-home-environment.md` | Shell config, dotfiles, WSL notes |
| `01-agent-setup.md` | Claude, Cursor CLI, Codex, rules/skills |
| `02-core-tools.md` | GitHub CLI, jq, Docker |
| `03-dev-environment.md` | Node.js/nvm, SDKMAN, Java, Quarkus, Maven |
| `04-ide+tooling.md` | Cursor IDE, keybindings, Java extensions |
| `05-voice-tools-*.md` | Voice input (Faster Whisper, nerd-dictation) |
| `06-optional.md` | Helm, Minikube, kubectl |

### Config Files (`configs/`)

Ready-to-use configuration files for common tools.

## Setting up for the first time

1. This repo has been cloned to /home/dave/projects/agent-box-setup
2. Follow the numbered guides in the `setup/` directory, see the section in "What's Included" below
3. Copy/symlink the configs from the `configs/` directory to the appropriate destinations
4. Verify with `SETUP.md` and generate a report.

## Synchronizing settings

TBD, we need a way to sync settings from / to machines
