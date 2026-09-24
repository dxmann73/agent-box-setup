# cursor-login recipe

Run after `cursor-cli` on each catalog-ticked daily host or agent VM. The interactive command
creates Cursor's local authentication state; `agent-config` separately preserves the
repository-managed CLI settings.

```bash
cd ~/projects/agent-box-setup/modules/06-cred/cursor-login
./apply.sh --target daily-host
./verify.sh --target daily-host
```

Use `--target agent-vm` inside the VM after `clean-guest`. If the login browser must stay external,
run `NO_OPEN_BROWSER=1 agent login` and open the supplied URL manually.
