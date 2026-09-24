# agent-config recipe

Run after all four agent CLI modules on each catalog-ticked daily host or agent VM. This module
links tracked global instructions, shared skills, Claude and Codex settings, and Cursor hooks. It
then merges only the tracked Cursor settings into its live configuration, preserving its login data.

The skill index is linked at the directory level. No individual directory under `agents/skills/` may
be a symlink: BB and Codex reject those skill roots while other agents silently follow them.

```bash
./apply.sh --target daily-host
./verify.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM. Authentication remains separate credential modules.
