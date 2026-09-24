# pi-login recipe

Run after `pi` on each catalog-ticked daily host or agent VM. Pi's interactive `/login` command owns
the chosen provider and writes its local state. This module does not prescribe a provider, model,
API key, or shared credential.

```bash
cd ~/projects/agent-box-setup/modules/06-cred/pi-login
./apply.sh --target daily-host
./verify.sh --target daily-host
```

At the Pi prompt, run `/login` and complete the provider flow. Use `--target agent-vm` only after
the credential-free `clean-guest` snapshot. Do not symlink or copy `~/.pi/agent/auth.json`.
