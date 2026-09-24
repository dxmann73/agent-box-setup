# codex-login recipe

Run after `codex-cli` on every catalog-ticked daily host or agent VM. Normal login opens the local
browser callback flow. Use device authentication when the browser is on a different machine or the
local callback is unavailable.

```bash
cd ~/projects/agent-box-setup/modules/06-cred/codex-login
./apply.sh --target daily-host
./verify.sh --target daily-host
```

For a separate browser or headless path, use `./apply.sh --target agent-vm --device-auth`, open the
printed URL yourself, and enter the one-time code. Never share the device code or copy
`~/.codex/auth.json` between targets.
