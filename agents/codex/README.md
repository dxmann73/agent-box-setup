# Codex CLI

Install Codex from the user-owned npm prefix:

```bash
npm install -g @openai/codex
codex
```

Authenticate on first launch. Link the shared configuration and Caveman hook:

```bash
mkdir -p ~/.codex
ln -sfn ~/projects/agent-box-setup/agents/codex/config.toml ~/.codex/config.toml
ln -sfn ~/projects/agent-box-setup/agents/codex/hooks.json ~/.codex/hooks.json
```

Verify:

```bash
codex --version
ls -l ~/.codex/config.toml ~/.codex/hooks.json
```

## Checklist

- [ ] `codex --version` succeeds
- [ ] Codex is authenticated
- [ ] configuration and Caveman hook files are symlinked
