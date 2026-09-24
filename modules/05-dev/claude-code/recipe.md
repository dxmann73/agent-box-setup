# claude-code recipe

Run after `kubuntu-desktop` on each catalog-ticked daily host and agent VM. This uses Anthropic's
native installer and does not invoke `claude`, so authentication remains the later `claude-login`
module. Shared settings and the statusline are linked by `agent-config`.

```bash
./apply.sh --target daily-host
./verify.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM.
