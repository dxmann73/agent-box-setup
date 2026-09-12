# Pi

Install Pi and link its instructions and skills:

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
mkdir -p ~/.pi/agent
ln -sfn ~/projects/agent-box-setup/agents/AGENTS.md ~/.pi/agent/AGENTS.md
ln -sfn ~/projects/agent-box-setup/agents/skills ~/.pi/agent/skills
```

Start `pi` and run `/login`. The optional Plasma launcher opens Pi in WezTerm:

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
- [ ] Pi is authenticated
- [ ] global instructions and skills are symlinked under `~/.pi/agent/`
