# Cursor CLI

Install Cursor CLI and authenticate:

```bash
curl -fsS https://cursor.com/install | bash
agent
```

Cursor manages `~/.cursor/cli-config.json`. Link the Caveman hook files:

```bash
mkdir -p ~/.cursor
ln -sfn ~/projects/agent-box-setup/agents/cursor/hooks.json ~/.cursor/hooks.json
ln -sfn ~/projects/agent-box-setup/agents/cursor/hooks ~/.cursor/hooks
```

Verify:

```bash
agent --version
echo '{"session_id":"verify","is_background_agent":false}' | ~/.cursor/hooks/caveman.sh
```

## Checklist

- [ ] `agent --version` succeeds
- [ ] Cursor CLI is authenticated
- [ ] Caveman hook files are symlinked and return `additional_context`
