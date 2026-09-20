---
name: bb-sudo-terminal
description: Start or verify a BB side terminal that keeps host sudo authenticated
  for rootful setup work. Use for /bb-sudo-terminal, sudo babysit, or BB sudo
  terminal requests.
---

# BB Sudo Terminal

Start a BB side terminal running the repo's `host-sudo-session` babysit helper. The user enters the
sudo password in that terminal; never ask for, echo, or send the password yourself.

## Workflow

1. Read BB context:

```bash
bb status --json
```

2. Create a terminal scoped to the current thread:

```bash
bb terminal create --thread THREAD_ID --title "sudo babysit" \
  --command "cd /home/dave/projects/agent-box-setup/modules/00-os/host-sudo-session && ./keepalive.sh" \
  --json
```

3. Read initial output:

```bash
bb terminal output TERM_ID --tail-bytes 4096
```

Tell the user to enter their sudo password in that side terminal if it is waiting at the password
prompt.

4. After the user says it is done, verify the terminal:

```bash
/home/dave/projects/agent-box-setup/modules/00-os/host-sudo-session/verify.sh --terminal-id TERM_ID
```

## Notes

- Do not use `--cwd` with `--thread`; thread-scoped BB terminals reject it. Put `cd ... &&` inside
  the command.
- `sudo -n` in the agent's own shell may fail even while the BB side terminal is authenticated.
  Sudo timestamps are usually terminal-scoped.
- Host sudo must remain password-protected. Do not add `NOPASSWD` on host.
