# tailscale-login recipe

Run after `tailscale` on each catalog-ticked daily host or agent VM. This authorizes exactly one
machine with the existing tailnet; it does not create auth keys or change routes, tags, DNS, ACLs,
SSH policy, or Serve configuration.

```bash
cd ~/projects/agent-box-setup/modules/06-cred/tailscale-login
./apply.sh --target daily-host
./verify.sh --target daily-host
```

Use `--target agent-vm` inside the VM after `clean-guest`. Node identity, tailnet names, and access
policy remain in `infra`; do not put them in this generic recipe.
