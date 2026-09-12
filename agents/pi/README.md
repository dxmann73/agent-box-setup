# Pi

Install Pi from the user-owned npm prefix, then authenticate in its first session:

```bash
npm install -g --ignore-scripts @earendil-works/pi-coding-agent
pi
```

Run `/login` to authenticate. Link the global instructions and skills:

```bash
mkdir -p ~/.pi/agent
ln -sfn ~/projects/agent-box-setup/agents/AGENTS.md ~/.pi/agent/AGENTS.md
ln -sfn ~/projects/agent-box-setup/agents/skills ~/.pi/agent/skills
```

Verify:

```bash
pi --version
ls -l ~/.pi/agent/AGENTS.md ~/.pi/agent/skills
```

Pi reads `~/.pi/agent/AGENTS.md` and discovers skills below `~/.pi/agent/skills/`. See the
[official Pi quickstart](https://pi.dev/docs/latest/quickstart).

## Checklist

- [ ] `pi --version` succeeds
- [ ] Pi is authenticated
- [ ] global instructions and skills are symlinked under `~/.pi/agent/`
