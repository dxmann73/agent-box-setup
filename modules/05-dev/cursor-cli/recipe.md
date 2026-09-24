# cursor-cli recipe

Run after `kubuntu-desktop` on catalog-ticked daily hosts and agent VMs. The Cursor installer
provides both `agent` and `cursor-agent`; neither is launched during installation, so login remains
the later `cursor-login` module. `agent-config` links hooks and merges the non-credential settings.

```bash
./apply.sh --target daily-host
./verify.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM.
