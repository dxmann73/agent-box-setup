# Pi

Install Pi and link its instructions. Pi discovers shared skills through `~/.agents/skills`.

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
mkdir -p ~/.pi/agent
ln -sfn ~/projects/agent-box-setup/agents/AGENTS.md ~/.pi/agent/AGENTS.md
```

Authentication is target-specific. During host completion, start `pi` and run `/login`. Guest
modules install Pi and its links but must not run `/login`; do so only in the later catalog login
window after the credential-free snapshot. Pi manages `~/.pi/agent/auth.json`; never track or
symlink it.

The optional Plasma launcher opens Pi in WezTerm:

```bash
mkdir -p ~/.local/bin ~/.local/share/applications
ln -sfn ~/projects/agent-box-setup/user-home/pi-launch.sh ~/.local/bin/pi-launch.sh
ln -sfn ~/projects/agent-box-setup/user-home/applications/pi.desktop \
  ~/.local/share/applications/pi.desktop
update-desktop-database ~/.local/share/applications
```

See the [Pi quickstart](https://pi.dev/docs/latest/quickstart).

## Checklist

- [ ] `pi --version` succeeds
- [ ] Pi is authenticated when the target's credentials phase requires it
- [ ] global instructions are symlinked under `~/.pi/agent/`
- [ ] shared skills resolve through `~/.agents/skills`
