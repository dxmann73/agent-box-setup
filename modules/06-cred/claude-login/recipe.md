# claude-login recipe

Run after `claude-code` on every catalog-ticked daily host or agent VM. It creates local provider
state only; the repository-managed settings remain owned by `agent-config`.

```bash
cd ~/projects/agent-box-setup/modules/06-cred/claude-login
./apply.sh --target daily-host
./verify.sh --target daily-host
```

Use `--target agent-vm` inside the VM after `clean-guest`. Keep target sessions separate so either
authorization can be revoked without affecting the other.
