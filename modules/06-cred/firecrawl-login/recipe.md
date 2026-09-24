# firecrawl-login recipe

Run after `firecrawl-cli` on every catalog-ticked daily host or agent VM. Browser login stores the
CLI session locally. The shell environment also needs that target's `FIRECRAWL_API_KEY` in its
ignored secrets file.

```bash
cd ~/projects/agent-box-setup/modules/06-cred/firecrawl-login
./apply.sh --target daily-host
```

Create the ignored source file once, replace only the placeholder with the target's key, and keep
the home path as a symlink. Do not paste the key into the terminal, a command history, or this repo.

```bash
repo=~/projects/agent-box-setup
install -m 0600 "$repo/user-home/.bash_secrets.CHANGE-ME" "$repo/user-home/.bash_secrets"
nano "$repo/user-home/.bash_secrets"
ln -sfn "$repo/user-home/.bash_secrets" ~/.bash_secrets
```

Then verify the login and file layout:

```bash
./verify.sh --target daily-host
```

Use `--target agent-vm` inside the VM after `clean-guest`. Each target has its own ignored source
file and Firecrawl session; do not transfer either between host and guest.
