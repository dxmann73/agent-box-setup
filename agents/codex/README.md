# Codex CLI

Codex CLI is the terminal command named `codex`. It is installed from npm.

Install Codex from the user-owned npm prefix:

```bash
npm install -g @openai/codex
codex
```

Authenticate on first launch. Link the repo-managed configuration and Caveman hook as the source of
truth:

```bash
mkdir -p ~/.codex
ln -sfn ~/projects/agent-box-setup/agents/codex/config.toml ~/.codex/config.toml
ln -sfn ~/projects/agent-box-setup/agents/codex/hooks.json ~/.codex/hooks.json
```

Do not replace this with a host-local config file. If Codex behavior needs to change, update the
tracked config and verification together.

Verify:

```bash
codex --version
ls -l ~/.codex/config.toml ~/.codex/hooks.json
```

## Checklist

- [ ] `codex --version` succeeds
- [ ] Codex is authenticated
- [ ] configuration and Caveman hook files are symlinked

When the personal browser runs in a separate guest, prefer `codex login --device-auth`. Open the
printed URL yourself and enter its one-time device code; never share that code or copy the resulting
credential state between targets. Keep existing authenticated sessions.
