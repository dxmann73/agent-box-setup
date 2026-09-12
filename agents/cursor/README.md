# Cursor CLI

Install Cursor CLI and authenticate:

```bash
curl -fsS https://cursor.com/install | bash
agent
```

Link the Caveman hook files:

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

## CLI settings

Close Cursor, then apply the repository template:

```bash
agents/cursor/apply-cli-config.sh
```

It manages `display`, `editor`, `network`, and `attribution`, preserving login data. Use
`--permissions` only for the unrestricted VM profile.

## Checklist

- [ ] `agent --version` succeeds
- [ ] Cursor CLI is authenticated
- [ ] Caveman hook files are symlinked and return `additional_context`
- [ ] `agents/cursor/apply-cli-config.sh` has been run and the statusline is visible
