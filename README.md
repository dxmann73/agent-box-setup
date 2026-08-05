# Agent Box Setup

Markdown-based setup documentation for configuring new coding agent VMs / machines.

The steps outlined here will assume you have already done the [bootstrapping](./BOOTSTRAP.md)!

## Why

1. To unlock the power of coding agents, they need to run in YOLO mode.
2. To reduce the blast radius, agents will need to run fully isolated in a sandbox.
3. To automate the setup itself, and also sync changes to the current setup to existing machines, we
   need a repo that holds both the configuration as well as the instructions to synchronize it.

## Scope: box-level vs. project-level

The repo name is historical. Not everything in here is machine setup — two different scopes live
side by side:

- **Box-level** — installed once per machine: shell/dotfiles, agent binaries, Docker, Node, Java,
  IDE. This is the `setup/` numbered guides.
- **Project-level** — belongs to whatever you are working on, and is only wired globally because
  there is no better home yet: skills in `configs/agents/skills/`, rules in
  `configs/agents/user-rules/`, and language toolchains that only some projects need (SDKMAN,
  Quarkus, pnpm).

Project-level items are installed globally (symlinked into `~/.claude/skills`, `~/.cursor/skills`)
as an interim measure so every project gets them. The intended end state is packaging them per
project type — see the "project setup" entry in [TODOs.md](./TODOs.md). When adding something,
decide which scope it belongs to first.

## Usage

This repo is designed to work with coding agents. Just tell them to "Set up this machine using the agent-box-setup
repo".

## What's Included

### Setup Guides (`setup/`)

| File                     | Description                                                    |
| ------------------------ | -------------------------------------------------------------- |
| `00-home-environment.md` | Shell config, dotfiles, WSL notes                              |
| `01-agent-setup.md`      | Claude, Cursor CLI, Codex, rules/skills                        |
| `02-core-tools.md`       | GitHub CLI, jq, Docker                                         |
| `03-dev-environment.md`  | Node.js/nvm, pnpm, Firecrawl CLI, SDKMAN, Java, Quarkus, Maven |
| `04-ide+tooling.md`      | Cursor IDE, keybindings, Java extensions                       |
| `05-voice-tools-*.md`    | Voice input (Faster Whisper, nerd-dictation)                   |
| `06-optional.md`         | Helm, Minikube, kubectl                                        |
| `08-local-whisper.md`    | Reference notes: Windows Whisper setup (not a setup step)      |

### Config Files (`configs/`)

Ready-to-use configuration files for common tools.

## Setting up for the first time

1. This repo has been cloned to `~/projects/agent-box-setup`
2. Follow the numbered guides in the `setup/` directory, see the section in "What's Included" below
3. Copy/symlink the configs from the `configs/` directory to the appropriate destinations
4. Verify with `SETUP.md` and generate a report.

## Synchronizing settings

TBD, we need a way to sync settings from / to machines
