# tailscale recipe

Run after `kubuntu-desktop` on every catalog-ticked daily host or agent VM. This installs the
Tailscale package and enables its daemon without joining a tailnet. `tailscale-login` separately
owns account authorization and node identity. Tailnet names, ACLs, SSH policy, and Serve origins
remain in `infra`.

```bash
cd ~/projects/agent-box-setup/modules/05-dev/tailscale
sudo ./apply.sh --target daily-host
./verify.sh --target daily-host
```

Use `--target agent-vm` inside the agent VM.
