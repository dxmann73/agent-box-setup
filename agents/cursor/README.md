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
ln -sfn ~/projects/agent-box-setup/agents/cursor/statusline.sh ~/.cursor/statusline.sh
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

It manages `display`, `editor`, `network`, `attribution`, and `statusLine`, preserving login
data. Use `--permissions` only for the unrestricted VM profile.

## Status line

`statusline.sh` shows model, context window usage, plan usage, and the billing reset date:

```text
Cursor Grok 4.6 Medium · ctx 42.4% of 200k · plan 33% ($6.51/$20) · resets Sep 28
```

Context data comes from Cursor's status line payload. Plan usage does not exist in that
payload, so the script calls the internal `aiserver.v1.DashboardService/GetCurrentPeriodUsage`
RPC (the call behind `/usage`) with the token from `~/.config/cursor/auth.json`. The result is
cached in `~/.cache/cursor-statusline/` and refreshed in the background every 60 seconds. The
API is undocumented; when it fails, the line shows `plan n/a` and the reason is written to
`~/.cache/cursor-statusline/usage.error`.

Verify:

```bash
echo '{"model":{"id":"verify"},"context_window":{"context_window_size":200000,"used_percentage":10}}' \
    | ~/.cursor/statusline.sh
```

## Checklist

- [ ] `agent --version` succeeds
- [ ] Cursor CLI is authenticated
- [ ] Caveman hook files are symlinked and return `additional_context`
- [ ] `~/.cursor/statusline.sh` is symlinked and prints a status line
- [ ] `agents/cursor/apply-cli-config.sh` has been run and the statusline is visible
