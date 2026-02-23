# Instructions for setting up an Agent Box

This repository contains instructions for setting up a new Ubuntu development machine to use to run agents in YOLO mode.

## How to Use This Repo

1. **Follow the numbered setup files in order** - Each file in `setup/` is numbered for sequential execution
2. **Verify each step** - Each setup file now includes verification commands after installation steps
3. **Run complete verification** - Use `./verify-setup.sh` to check all installations at once
4. **Copy configs** - Use files from `configs/` directory as templates

## Quick Verification

After setup or at any time, run the verification script to check all components:

```bash
cd ~/projects/agent-box-setup
./verify-setup.sh
```

This will verify:

- Agent binaries (Claude Code, Cursor CLI Agent, Cursor IDE)
- Home directory symlinks (`.bashrc`, `.bash_aliases`, `.profile`, `.gitconfig`, `.bash_secrets`, `.markdownlint.json`)
- Agent configuration and symlinks
- Rules and skills setup
- Core tools (GitHub CLI, Docker, jq)
- Development environment (Node.js, Java, etc.)
- Optional tools (if installed)

## Setup Order

1. [setup/00-home-environment.md](setup/00-home-environment.md) - Shell configuration and dotfiles
2. [setup/01-agent-setup.md](setup/01-agent-setup.md) - Claude Code, Cursor CLI, agent rules
3. [setup/02-core-tools.md](setup/02-core-tools.md) - GitHub CLI, jq, Docker
4. [setup/03-dev-environment.md](setup/03-dev-environment.md) - Node.js and development tools
5. [setup/04-ide+tooling.md](setup/04-ide+tooling.md) - Cursor IDE
6. [setup/05-voice-tools-a-faster-whisper.md](setup/05-voice-tools-a-faster-whisper.md) - Voice input (faster-whisper) — skip if Wispr Flow is already available
7. [setup/05-voice-tools-b-nerd-dictation.md](setup/05-voice-tools-b-nerd-dictation.md) - Voice input (nerd-dictation alternative) — skip if Wispr Flow is already available
8. [setup/06-optional.md](setup/06-optional.md) - Helm, cloud CLIs, extras

## Important Notes

- **Don't run everything blindly** - Ask the user before installing optional tools
- **Check existing installations** - Many tools may already be installed; verify first
- **Assume parallel agent work** - If unexpected changes appear, treat them as edits from another agent and work around them without reverting
- **Respect user preferences** - These are defaults; the user may want variations
- **Handle errors gracefully** - If a step fails, diagnose before continuing

## Project Rules

- Treat `configs/agents/skills/` as the single source of truth for installed skills.
- Keep setup docs/scripts in sync with that directory (`setup/01-agent-setup.md`, `verify-setup.sh`, `SETUP.md`).
- Verification must be directory-driven (derive expected skills from `configs/agents/skills/`), not hardcoded skill-name lists.

## Config Files

The `configs/user-home-directory/` contains dotfiles that must be **symlinked** (not copied) to `~`:

- `.bashrc` - Bash shell configuration
- `.bash_aliases` - Custom command aliases
- `.bash_secrets` - API tokens/secrets (created from `.bash_secrets.CHANGE-ME` template)
- `.profile` - User profile settings
- `.gitconfig` - Git configuration

The repo root `.markdownlint.json` is symlinked to `~/projects/.markdownlint.json`.

See `setup/00-home-environment.md` for the full symlink commands.

## Structure

- `setup/` - Numbered setup guides (follow in order, each includes verification steps)
- `configs/` - Configuration files to copy/symlink
- `verify-setup.sh` - Automated verification script (run this to check everything)
- `SETUP.md` - Detailed verification checklist with troubleshooting
