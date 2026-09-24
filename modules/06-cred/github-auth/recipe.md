# github-auth recipe

Run after `github-cli` on each catalog-ticked daily host or agent VM. This gives each target an
independent GitHub authorization and configures HTTPS Git to use the GitHub CLI credential helper.

```bash
cd ~/projects/agent-box-setup/modules/06-cred/github-auth
./apply.sh --target daily-host
./verify.sh --target daily-host
```

Use `--target agent-vm` inside the VM after its credential-free snapshot. Revoke a target through
GitHub's authorized-apps settings; never copy its token, credential helper state, or Git config to
another target.
