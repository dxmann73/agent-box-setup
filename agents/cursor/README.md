# Cursor CLI Agent

## Installation

As per the [installation instructions](https://cursor.com/docs/cli/installation)

```bash
curl https://cursor.com/install -fsS | bash
```

**Verify installation:**

```bash
agent --version
```

Expected output: `2026.xx.xx-xxxxxxx` or similar

**Troubleshooting:** If `agent` command is not found, ensure `~/.local/bin` is in your PATH:

```bash
echo $PATH | grep -q "$HOME/.local/bin" && echo "✓ PATH is configured" || echo "✗ Add ~/.local/bin to PATH"
```

## Settings

As per the [documentation for Cursor CLI](https://cursor.com/docs/cli/reference/configuration),
settings are stored in `~/.cursor/cli-config.json`. Cursor manages this file directly — do not
symlink it.

`agents/cursor/cli-config.json` is kept as a reference snapshot (credentials masked) to
compare settings across machines. On setup, diff and reconcile the two:

```bash
diff <(jq 'del(.authInfo, .privacyCache)' \
        ~/projects/agent-box-setup/agents/cursor/cli-config.json) \
     <(jq 'del(.authInfo, .privacyCache)' \
        ~/.cursor/cli-config.json)
```

Copy any desired settings from the reference into `~/.cursor/cli-config.json` manually.

**Key settings:**

- `approvalMode: "unrestricted"` — YOLO / "Run Everything". Valid values are `"allowlist"`
  (default, prompt per command) and `"unrestricted"` (skip all approvals). The public docs at
  `cursor.com/docs/cli/reference/configuration` don't list these enum values; they come from the
  CLI's bundled config schema (`cursor-agent` 2026.05+). The `--force` / `--yolo` CLI flags are
  the per-invocation equivalent.
- `permissions.allow: ["Shell(*)"]` — auto-approve all shell commands (belt-and-braces with
  `approvalMode: "unrestricted"`).
- `sandbox.mode: "disabled"` — no sandboxing. Pair `approvalMode: "unrestricted"` with
  `sandbox.mode: "enabled"` if you want YOLO without giving up host isolation.
- `attribution.attributeCommitsToAgent: true` — commits are attributed to the agent.

## Caveman

See [../README.md#caveman](../README.md#caveman) for the clone step.

Cursor now has [hooks](https://cursor.com/docs/hooks) (IDE and CLI). Caveman uses a user-level
`sessionStart` hook that returns `additional_context`, so it is active from the first response of
each session. Say "stop caveman" or "normal mode" to deactivate.

Source: `agents/cursor/hooks.json` + `agents/cursor/hooks/`
Destination: `~/.cursor/hooks.json` + `~/.cursor/hooks/`

```bash
ln -sfn ~/projects/agent-box-setup/agents/cursor/hooks.json ~/.cursor/hooks.json
ln -sfn ~/projects/agent-box-setup/agents/cursor/hooks ~/.cursor/hooks
```

Hook text lives in `agents/cursor/hooks/caveman.md`; the script wraps it as JSON and needs
`jq` (installed in `machines/common/02-core-tools.md`).

**Verify hook:**

```bash
echo '{"session_id":"test","is_background_agent":false}' | ~/.cursor/hooks/caveman.sh
```

Expected: JSON with an `additional_context` field. Cursor also has a Hooks tab in **Customize** to
confirm the hook is loaded.

**Next:** [../codex/README.md](../codex/README.md)
